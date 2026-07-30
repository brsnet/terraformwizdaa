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

        # Without this, ignoreDifferences only suppresses drift *reporting* —
        # any sync (even one triggered by an unrelated resource in this app)
        # still applies git's version of the ignored fields, wiping leads-env's
        # real values. This makes sync use the *live* value for ignored fields
        # instead, so real secret data survives every future sync.
        syncOptions = ["RespectIgnoreDifferences=true"]
      }

      # leads-env's data is filled in by hand after sync (via kubectl/Argo CD UI),
      # not committed to git — ignore drift so selfHeal doesn't wipe it back out.
      ignoreDifferences = [
        {
          group        = ""
          kind         = "Secret"
          name         = "leads-env"
          namespace    = kubernetes_namespace.realtor_apps.metadata[0].name
          jsonPointers = ["/data", "/stringData"]
        }
      ]
    }
  }

  field_manager {
    force_conflicts = true
  }
}
