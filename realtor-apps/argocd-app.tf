resource "kubernetes_manifest" "leads_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "leads"
      namespace = var.argocd_namespace
    }

    spec = {
      project = "default"

      source = {
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        path           = var.repo_path
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.realtor_apps.metadata[0].name
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}
