output "namespace_name" {
  description = "Shared namespace the realtor apps are deployed into"
  value       = kubernetes_namespace.realtor_apps.metadata[0].name
}

output "app_names" {
  description = "Apps registered with Argo CD from local.apps"
  value       = sort(keys(local.apps))
}

output "app_urls" {
  description = "URL each app's LoadBalancer Service is reachable at (Docker Desktop binds LoadBalancer services to localhost)"
  value       = { for name, cfg in local.apps : name => "http://localhost:${cfg.port}" }
}
