output "namespace_name" {
  description = "Namespace the Leads app is deployed into"
  value       = kubernetes_namespace.realtor_apps.metadata[0].name
}

output "leads_url" {
  description = "URL where the Leads app is always reachable"
  value       = "http://localhost:6000"
}
