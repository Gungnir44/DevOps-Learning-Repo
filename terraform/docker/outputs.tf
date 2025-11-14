# Outputs for Terraform Docker infrastructure

output "network_id" {
  description = "Docker network ID"
  value       = docker_network.monitoring_network.id
}

output "network_name" {
  description = "Docker network name"
  value       = docker_network.monitoring_network.name
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://localhost:${var.prometheus_port}"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://localhost:${var.grafana_port}"
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value = {
    username = var.grafana_admin_user
    password = var.grafana_admin_password
  }
  sensitive = true
}

output "redis_connection" {
  description = "Redis connection string"
  value       = "redis://localhost:${var.redis_port}"
}

output "postgres_connection" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.postgres_user}:${var.postgres_password}@localhost:${var.postgres_port}/${var.postgres_db}"
  sensitive   = true
}

output "container_ids" {
  description = "Container IDs"
  value = {
    prometheus = docker_container.prometheus.id
    grafana    = docker_container.grafana.id
    redis      = docker_container.redis.id
    postgres   = docker_container.postgres.id
  }
}

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment = var.environment
    containers = {
      prometheus = docker_container.prometheus.name
      grafana    = docker_container.grafana.name
      redis      = docker_container.redis.name
      postgres   = docker_container.postgres.name
    }
    endpoints = {
      prometheus = "http://localhost:${var.prometheus_port}"
      grafana    = "http://localhost:${var.grafana_port}"
    }
  }
}
