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
