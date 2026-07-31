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

# Shared by every app in local.apps — owned by this root only. Per-app config
# belongs in apps.tf and <app>/manifests/, never in a separate Terraform root
# that would try to create this namespace a second time.
resource "kubernetes_namespace" "realtor_apps" {
  metadata {
    name = var.namespace

    labels = {
      managed-by  = "terraform"
      environment = "lab"
      project     = "realtor-apps"
    }
  }
}
