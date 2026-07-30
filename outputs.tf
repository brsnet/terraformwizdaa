output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace.wizdaa_lab.metadata[0].name
}

output "namespace_uid" {
  description = "UID of the created namespace"
  value       = kubernetes_namespace.wizdaa_lab.metadata[0].uid
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}
