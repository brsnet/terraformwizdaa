# Wizdaa — Local Kubernetes Lab

A local technical lab using the Kubernetes cluster built into Docker Desktop to practice Kubernetes, Argo CD, Terraform, GitOps, Linux and container troubleshooting, deployments, observability concepts, and platform engineering scenarios.

## Architecture

```
Windows 10/11
├── Docker Desktop
│   └── Built-in Kubernetes cluster
│       └── kubeconfig context: docker-desktop
├── PowerShell or Windows Terminal
├── kubectl
├── Terraform CLI
├── Argo CD CLI (argocd)
├── Git
└── VS Code
```

WSL2 is optional. The simplest path is to run the lab from PowerShell or Windows Terminal.

## Minimum Requirements

| Resource | Minimum |
|----------|---------|
| CPU cores | 4 |
| RAM | 8 GB (12–16 GB preferred) |
| Free disk | 20 GB |
| Virtualization | Enabled |
| Docker Desktop | Linux containers mode |

---

## Setup

### 1. Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Go to **Settings → Kubernetes**
3. Enable Kubernetes or select **Create cluster**
4. Use the Docker Desktop provisioner
5. Wait until the cluster status is healthy

> Do not use **Reset Kubernetes Cluster** unless you intentionally want to delete all local cluster state.

### 2. Verify the context

```powershell
kubectl config get-contexts
kubectl config use-context docker-desktop
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A
```

Expected context: `docker-desktop`

### 3. Install or verify tools

```powershell
# Required
kubectl version --client
git --version
terraform version
argocd version --client
```

Optional tools: Helm, k9s, jq, yq, curl, OpenSSL, VS Code extensions (Kubernetes, Terraform, YAML)

### 4. Validate the environment

```powershell
docker version
kubectl config current-context   # must return: docker-desktop
kubectl get nodes
kubectl get pods -A
terraform version
argocd version --client
```

---

## Terraform

### Provider configuration

```hcl
provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes {
    config_path    = pathexpand("~/.kube/config")
    config_context = "docker-desktop"
  }
}
```

### Apply

```powershell
kubectl config use-context docker-desktop

terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
```

`terraform apply` creates the `wizdaa-lab` namespace and installs Argo CD (via the `argo-cd` Helm chart from `argo-helm`) into the `argocd` namespace in one step — no manual `kubectl apply` needed. See [Argo CD (GitOps)](#argo-cd-gitops) below.

### Variables

| Name | Default | Description |
|------|---------|-------------|
| `kube_context` | `docker-desktop` | kubeconfig context to target |
| `namespace` | `wizdaa-lab` | Name of the namespace to create |
| `argocd_namespace` | `argocd` | Namespace to install Argo CD into |
| `argocd_chart_version` | `null` (latest) | Version of the `argo-cd` Helm chart to install |
| `argocd_expose_port` | `7000` | Host port that always exposes the Argo CD UI/API via a `LoadBalancer` service |

### Outputs

| Name | Description |
|------|-------------|
| `namespace_name` | Name of the created namespace |
| `namespace_uid` | UID assigned by Kubernetes |
| `argocd_namespace` | Namespace where Argo CD is installed |
| `argocd_url` | URL where the Argo CD UI is always reachable |

### Destroy

```powershell
terraform destroy
```

---

## Safe First Deployment (kubectl)

```powershell
kubectl create namespace wizdaa-lab

kubectl create deployment web `
  --image=nginx:alpine `
  -n wizdaa-lab

kubectl expose deployment web `
  --port=80 `
  --type=ClusterIP `
  -n wizdaa-lab

kubectl get all -n wizdaa-lab
```

Test with port forwarding:

```powershell
# Terminal 1
kubectl port-forward service/web 8080:80 -n wizdaa-lab

# Terminal 2
curl http://localhost:8080
```

---

## Argo CD (GitOps)

### Install

Argo CD is installed by Terraform (`argocd.tf`) via the official [`argo-helm`](https://github.com/argoproj/argo-helm) chart — `terraform apply` creates the `argocd` namespace and installs the `argo-cd` Helm release into it, so no manual `kubectl apply` of the raw manifests is needed:

```powershell
terraform apply
kubectl get pods -n argocd
```

Pin the chart version with `-var="argocd_chart_version=X.Y.Z"` (or set it in a `.tfvars` file) if you need reproducible installs instead of always tracking the latest chart.

### Access the UI

Terraform also creates a `LoadBalancer` service (`argocd-server-lb`, see `argocd.tf`) that always exposes the Argo CD server on `https://localhost:7000` — Docker Desktop binds `LoadBalancer` services directly to `localhost`, so no `kubectl port-forward` is needed. The port is configurable via the `argocd_expose_port` variable and available as the `argocd_url` output.

```powershell
# Retrieve the initial admin password
kubectl get secret argocd-initial-admin-secret -n argocd `
  -o jsonpath="{.data.password}" | [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
```

Open `https://localhost:7000` in your browser and log in with username `admin` and the password above.

### Login via CLI

```powershell
argocd login localhost:7000 --username admin --insecure
```

### Deploy an application

```powershell
argocd app create wizdaa-lab `
  --repo https://github.com/<your-org>/<your-repo>.git `
  --path manifests `
  --dest-server https://kubernetes.default.svc `
  --dest-namespace wizdaa-lab `
  --sync-policy automated

argocd app sync wizdaa-lab
argocd app get wizdaa-lab
```

This connects Argo CD to a Git repository and syncs the manifests in `manifests/` into the `wizdaa-lab` namespace automatically.

### Example: `realtor-apps/` — Leads app via Argo CD

`realtor-apps/` is a self-contained Terraform module (its own state) that:

- Creates the `realtor-apps` namespace
- Creates an Argo CD `Application` (`kubernetes_manifest.leads_application`) that syncs `realtor-apps/manifests/` from **this same repo** into that namespace — a self-referencing GitOps setup, since [brsnet/Leads](https://github.com/brsnet/Leads) itself has no Kubernetes manifests
- `realtor-apps/manifests/deployment.yaml` and `service.yaml` define the actual `leads` Deployment (image `leads-leads:latest`, app listens on container port `6000`, set via the `PORT` env var in `leads-env`) and a `LoadBalancer` Service always exposing it at `http://localhost:8080` externally, proxied to the container's port `6000` (same Docker Desktop `LoadBalancer` behavior used for the Argo CD UI)
- `realtor-apps/manifests/secret.yaml` defines the `leads-env` Secret with empty placeholders for every env var the Leads app reads (`PORT`, `API_KEY`, `DB_DSN`, `DB_PATH`, `EVOLUTION_BASE_URL`, `EVOLUTION_API_KEY`, `EVOLUTION_INSTANCE`, `META_PHONE_NUMBER_ID`, `META_ACCESS_TOKEN`, `SEND_RATE_PER_SECOND`, `SEND_BATCH_SIZE`, `DASHBOARD_USER`, `DASHBOARD_PASSWORD`); the Deployment wires them in via `envFrom.secretRef`

Apply order matters: the root config must be applied first (it installs the Argo CD CRDs this module's `kubernetes_manifest.leads_application` depends on).

```powershell
terraform apply                 # root: namespace + Argo CD
cd realtor-apps
terraform init
terraform apply                 # realtor-apps namespace + Argo CD Application
```

The Argo CD `Application` only syncs successfully once `realtor-apps/manifests/` exists on the branch it targets (`main` by default, see `target_revision` variable) — until this folder is merged, the app shows `ComparisonError` / sync status `Unknown` in the Argo CD UI, and self-heals once merged.

#### Filling in the Leads env secret

`leads-env`'s real values are **not** stored in git — fill them in directly on the live cluster after the app syncs:

```powershell
kubectl edit secret leads-env -n realtor-apps
# or, via the Argo CD UI: Application "leads" → leads-env → Edit
```

The Argo CD `Application`'s `ignoreDifferences` (on `Secret.leads-env`'s `/data` field) keeps `selfHeal` from reverting those values back to the empty placeholders committed in git.

---

## OpenShift (Optional)

Use **Red Hat OpenShift Local** only when you need to practice:

- `oc` CLI
- Projects, Routes, Security Context Constraints
- Operators, BuildConfigs, ImageStreams
- OpenShift console workflows

OpenShift Local is significantly heavier than the Docker Desktop cluster. Do not replace a stable Docker Desktop setup shortly before an interview.

---

## Cleanup

```powershell
kubectl delete namespace wizdaa-lab --ignore-not-found
kubectl delete namespace argocd --ignore-not-found
```

Or via Terraform:

```powershell
terraform destroy
```
