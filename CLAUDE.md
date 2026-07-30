# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A minimal Terraform config that provisions a single Kubernetes namespace (`kubernetes_namespace.wizdaa_lab`) against a local Docker Desktop Kubernetes cluster. It's the Terraform piece of a larger local lab ("Wizdaa") for practicing Kubernetes, Argo CD, GitOps, and platform engineering — see `README.md` for the full lab setup (Docker Desktop, kubectl, Argo CD install/config, OpenShift notes).

Files:
- `main.tf` — provider config (`hashicorp/kubernetes`, targets `~/.kube/config`) and the namespace resource
- `variables.tf` — `kube_context` (default `docker-desktop`), `namespace` (default `wizdaa-lab`)
- `outputs.tf` — `namespace_name`, `namespace_uid`

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
