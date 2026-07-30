output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace.wizdaa_lab.metadata[0].name
}

output "namespace_uid" {
  description = "UID of the created namespace"
  value       = kubernetes_namespace.wizdaa_lab.metadata[0].uid
}
