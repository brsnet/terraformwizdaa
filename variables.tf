variable "kube_context" {
  description = "Kubernetes context to use from ~/.kube/config"
  type        = string
  default     = "docker-desktop"
}

variable "namespace" {
  description = "Name of the namespace to create"
  type        = string
  default     = "wizdaa-lab"
}

variable "argocd_namespace" {
  description = "Namespace to install Argo CD into"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the argo-cd Helm chart to install (see https://artifacthub.io/packages/helm/argo/argo-cd). Leave null to install the latest available version."
  type        = string
  default     = null
}
