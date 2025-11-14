# AWS ECS Deployment Variables

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# Prometheus configuration
variable "prometheus_cpu" {
  description = "CPU units for Prometheus (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "prometheus_memory" {
  description = "Memory for Prometheus in MB"
  type        = number
  default     = 2048
}

variable "prometheus_replica_count" {
  description = "Number of Prometheus replicas"
  type        = number
  default     = 1
}

variable "prometheus_min_replicas" {
  description = "Minimum number of Prometheus replicas for auto-scaling"
  type        = number
  default     = 1
}

variable "prometheus_max_replicas" {
  description = "Maximum number of Prometheus replicas for auto-scaling"
  type        = number
  default     = 3
}

# Grafana configuration
variable "grafana_cpu" {
  description = "CPU units for Grafana (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "grafana_memory" {
  description = "Memory for Grafana in MB"
  type        = number
  default     = 1024
}

variable "grafana_replica_count" {
  description = "Number of Grafana replicas"
  type        = number
  default     = 1
}

variable "grafana_min_replicas" {
  description = "Minimum number of Grafana replicas for auto-scaling"
  type        = number
  default     = 1
}

variable "grafana_max_replicas" {
  description = "Maximum number of Grafana replicas for auto-scaling"
  type        = number
  default     = 3
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
  sensitive   = true
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
