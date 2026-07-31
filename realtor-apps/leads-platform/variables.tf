variable "kube_context" {
  description = "Kubernetes context to use from ~/.kube/config"
  type        = string
  default     = "docker-desktop"
}

variable "namespace" {
  description = "Namespace to deploy the Leads app into"
  type        = string
  default     = "realtor-apps"
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD (and its Application CRs) is installed. Must already exist — apply the root terraform config first."
  type        = string
  default     = "argocd"
}

variable "repo_url" {
  description = "Git repo Argo CD syncs the Leads manifests from"
  type        = string
  default     = "https://github.com/brsnet/terraformwizdaa.git"
}

variable "repo_path" {
  description = "Path within repo_url containing the Leads Kubernetes manifests"
  type        = string
  default     = "realtor-apps/manifests"
}

variable "target_revision" {
  description = "Git branch/tag/commit Argo CD tracks for the Leads manifests"
  type        = string
  default     = "main"
}
