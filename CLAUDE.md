# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A minimal Terraform config that provisions a Kubernetes namespace (`kubernetes_namespace.wizdaa_lab`) and installs Argo CD (via the `argo-cd` Helm chart) against a local Docker Desktop Kubernetes cluster. It's the Terraform piece of a larger local lab ("Wizdaa") for practicing Kubernetes, Argo CD, GitOps, and platform engineering — see `README.md` for the full lab setup (Docker Desktop, kubectl, Argo CD usage, OpenShift notes).

Files:
- `main.tf` — provider config (`hashicorp/kubernetes`, `hashicorp/helm`, both targeting `~/.kube/config`) and the `wizdaa-lab` namespace resource
- `argocd.tf` — `argocd` namespace, the `helm_release.argocd` resource (chart from `https://argoproj.github.io/argo-helm`), and `kubernetes_service.argocd_server_lb`, a `LoadBalancer` service that always exposes the Argo CD server on a fixed host port (Docker Desktop binds `LoadBalancer` services directly to `localhost`, so no `kubectl port-forward` is needed)
- `variables.tf` — `kube_context` (default `docker-desktop`), `namespace` (default `wizdaa-lab`), `argocd_namespace` (default `argocd`), `argocd_chart_version` (default `null` = latest), `argocd_expose_port` (default `7000`)
- `outputs.tf` — `namespace_name`, `namespace_uid`, `argocd_namespace`, `argocd_url`

`terraform init` needs network access to pull the Argo CD Helm chart index from `argoproj.github.io/argo-helm`; `terraform apply` needs network access to pull the chart's container images into the cluster.

### `realtor-apps/` — separate Terraform module

A second, independent Terraform root (its own state, its own `terraform init`/`apply`) for deploying the `leads` app via Argo CD GitOps:

- `main.tf` — provider config + the `realtor-apps` namespace
- `argocd-app.tf` — `kubernetes_manifest.leads_application`, an Argo CD `Application` CR (in the `argocd` namespace) that syncs `realtor-apps/manifests/` from **this repo** (`repo_url`/`repo_path`/`target_revision` variables) into the `realtor-apps` namespace
- `manifests/deployment.yaml`, `manifests/service.yaml`, `manifests/secret.yaml` — the actual Kubernetes manifests Argo CD syncs (not applied directly by Terraform); the Leads app repo itself (`github.com/brsnet/Leads`) has no manifests, so these are authored and owned here
- Must be applied *after* the root module (its `kubernetes_manifest.leads_application` requires the Argo CD CRDs the root module installs), and its Argo `Application` only syncs successfully once `realtor-apps/manifests/` exists on the `target_revision` branch (default `main`)
- `manifests/secret.yaml` defines the `leads-env` Secret with empty placeholder values for every env var `config.go` (in the Leads repo) reads via `os.Getenv` — `PORT`, `API_KEY`, `DB_DSN`, `DB_PATH`, `EVOLUTION_BASE_URL`, `EVOLUTION_API_KEY`, `EVOLUTION_INSTANCE`, `META_PHONE_NUMBER_ID`, `META_ACCESS_TOKEN`, `SEND_RATE_PER_SECOND`, `SEND_BATCH_SIZE`, `DASHBOARD_USER`, `DASHBOARD_PASSWORD`. The Deployment consumes them via `envFrom.secretRef`. Real values are filled in by hand directly on the live Secret (`kubectl edit secret leads-env -n realtor-apps` or via the Argo CD UI) — never committed to git. `argocd-app.tf`'s `ignoreDifferences` (on `Secret.leads-env`'s `/data`) stops Argo's `selfHeal` from reverting those manually-filled values back to the empty ones in git.

## Commands

Target cluster must be `docker-desktop` (Docker Desktop's built-in Kubernetes), verified via `kubectl config current-context`.

```powershell
kubectl config use-context docker-desktop

terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

There is no test suite, linter config, or CI pipeline in this repo — `terraform validate`/`terraform plan` are the correctness checks.

## Notes

- `terraform.tfstate` / `terraform.tfstate.backup` are local state files checked into this directory (no remote backend) — be careful not to lose them, and don't hand-edit them.
- Everything here assumes the Docker Desktop Kubernetes cluster is running locally; there's no remote/cloud target.
