variable "kube_context" {
  description = "Kubernetes context to use from ~/.kube/config"
  type        = string
  default     = "docker-desktop"
}

variable "namespace" {
  description = "Shared namespace all realtor apps are deployed into"
  type        = string
  default     = "realtor-apps"
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD (and its Application CRs) is installed. Must already exist — apply the root terraform config first."
  type        = string
  default     = "argocd"
}

variable "repo_url" {
  description = "Git repo Argo CD syncs the app manifests from"
  type        = string
  default     = "https://github.com/brsnet/terraformwizdaa.git"
}

variable "repo_path_prefix" {
  description = "Directory within repo_url holding the per-app folders. Each app's manifests are read from <repo_path_prefix>/<app>/manifests."
  type        = string
  default     = "realtor-apps"
}

variable "target_revision" {
  description = "Git branch/tag/commit Argo CD tracks for the app manifests"
  type        = string
  default     = "main"
}
