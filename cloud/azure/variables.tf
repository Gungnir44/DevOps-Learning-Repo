# Azure AKS Deployment Variables

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.1.1.0/24"
}

# AKS configuration
variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes for auto-scaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "vm_size" {
  description = "Size of VMs in the node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

# Container Registry
variable "create_acr" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = true
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

# Monitoring stack configuration
variable "prometheus_replicas" {
  description = "Number of Prometheus replicas"
  type        = number
  default     = 1
}

variable "grafana_replicas" {
  description = "Number of Grafana replicas"
  type        = number
  default     = 1
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
