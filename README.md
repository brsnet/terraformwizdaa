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

### Variables

| Name | Default | Description |
|------|---------|-------------|
| `kube_context` | `docker-desktop` | kubeconfig context to target |
| `namespace` | `wizdaa-lab` | Name of the namespace to create |

### Outputs

| Name | Description |
|------|-------------|
| `namespace_name` | Name of the created namespace |
| `namespace_uid` | UID assigned by Kubernetes |

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

```powershell
# Create namespace and install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available deployment -l "app.kubernetes.io/name=argocd-server" -n argocd --timeout=120s
kubectl get pods -n argocd
```

### Access the UI

```powershell
# Port-forward the Argo CD API server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Retrieve the initial admin password
kubectl get secret argocd-initial-admin-secret -n argocd `
  -o jsonpath="{.data.password}" | [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
```

Open `https://localhost:8080` in your browser and log in with username `admin` and the password above.

### Login via CLI

```powershell
argocd login localhost:8080 --username admin --insecure
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
