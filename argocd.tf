resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace

    labels = {
      managed-by  = "terraform"
      environment = "lab"
      project     = "wizdaa"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  wait    = true
  timeout = 600
}

resource "kubernetes_service" "argocd_server_lb" {
  metadata {
    name      = "argocd-server-lb"
    namespace = kubernetes_namespace.argocd.metadata[0].name

    labels = {
      managed-by = "terraform"
      project    = "wizdaa"
    }
  }

  spec {
    type = "LoadBalancer"

    selector = {
      "app.kubernetes.io/instance" = "argocd"
      "app.kubernetes.io/name"     = "argocd-server"
    }

    port {
      name        = "https"
      port        = var.argocd_expose_port
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.argocd]
}
