locals {
  # Registry of apps deployed into var.namespace via Argo CD. Each key is the
  # app name — it must match both the Argo CD Application name and the
  # manifests folder (<key>/manifests/) this app's Deployment/Service/etc. live
  # in. Deployment/Service/image/port/env details all live in that folder's
  # YAML (git-synced by Argo CD), not here — this map only tells Terraform
  # which Argo CD Applications to create, which of them have a <key>-env Secret
  # whose data must be protected from selfHeal, and the host port their
  # LoadBalancer Service binds to (used for the app_urls output only — the
  # Service YAML remains the source of truth for the actual port).
  #
  # To add an app: add an entry here and create <key>/manifests/*.yaml.
  apps = {
    leads = {
      has_secret = true
      port       = 7001
    }
    leads-crawler = {
      has_secret = true
      port       = 7002
    }
  }
}
