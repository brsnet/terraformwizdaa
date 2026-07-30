terraform {
  required_version = ">= 1.3.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = var.kube_context
}

resource "kubernetes_namespace" "wizdaa_lab" {
  metadata {
    name = var.namespace

    labels = {
      managed-by  = "terraform"
      environment = "lab"
      project     = "wizdaa"
    }
  }
}
