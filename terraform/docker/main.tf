# Terraform configuration for Docker-based infrastructure
# Demonstrates Infrastructure as Code principles with local Docker

terraform {
  required_version = ">= 1.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # Backend configuration for state management
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"  # Windows
  # host = "unix:///var/run/docker.sock"   # Linux/Mac
}

# Networks
resource "docker_network" "monitoring_network" {
  name   = "terraform-monitoring-network"
  driver = "bridge"

  ipam_config {
    subnet  = "172.21.0.0/16"
    gateway = "172.21.0.1"
  }

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# Prometheus
resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  name  = "terraform-prometheus"
  image = docker_image.prometheus.image_id

  networks_advanced {
    name = docker_network.monitoring_network.name
  }

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path      = abspath("${path.module}/../../docker/prometheus/prometheus.yml")
    read_only      = true
  }

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# Grafana
resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_container" "grafana" {
  name  = "terraform-grafana"
  image = docker_image.grafana.image_id

  networks_advanced {
    name = docker_network.monitoring_network.name
  }

  ports {
    internal = 3000
    external = var.grafana_port
  }

  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
  ]

  restart = "unless-stopped"

  depends_on = [docker_container.prometheus]

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# Redis
resource "docker_image" "redis" {
  name = "redis:7-alpine"
  keep_locally = true
}

resource "docker_container" "redis" {
  name  = "terraform-redis"
  image = docker_image.redis.image_id

  networks_advanced {
    name = docker_network.monitoring_network.name
  }

  ports {
    internal = 6379
    external = var.redis_port
  }

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# PostgreSQL
resource "docker_image" "postgres" {
  name = "postgres:15-alpine"
  keep_locally = true
}

resource "docker_container" "postgres" {
  name  = "terraform-postgres"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.monitoring_network.name
  }

  ports {
    internal = 5432
    external = var.postgres_port
  }

  env = [
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=${var.postgres_db}",
  ]

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed_by"
    value = "terraform"
  }
}
