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
