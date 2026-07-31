locals {
  # Registry of apps deployed into var.namespace via Argo CD. Each key is the
  # app name — it must match both the Argo CD Application name and the
  # manifests subfolder (manifests/<key>/) this app's Deployment/Service/etc.
  # live in. Deployment/Service/image/port/env details all live in that
  # subfolder's YAML (git-synced by Argo CD), not here — this map only tells
  # Terraform which Argo CD Applications to create and which of them have a
  # <key>-env Secret that needs drift on its data protected from selfHeal.
  apps = {
    leads = {
      has_secret = true
    }
  }
}
