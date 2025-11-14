# Azure AKS Deployment for Monitoring Stack
# This Terraform configuration deploys the monitoring stack to Azure Kubernetes Service

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # Backend configuration for state management
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "devopsterraformstate"
    container_name       = "tfstate"
    key                  = "monitoring.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "monitoring" {
  name     = "monitoring-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "DevOps-Monitoring"
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "monitoring" {
  name                = "monitoring-vnet-${var.environment}"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  address_space       = [var.vnet_address_space]

  tags = {
    Environment = var.environment
  }
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.monitoring.name
  virtual_network_name = azurerm_virtual_network.monitoring.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

# Azure Container Registry (optional)
resource "azurerm_container_registry" "monitoring" {
  count               = var.create_acr ? 1 : 0
  name                = "monitoringacr${var.environment}"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = {
    Environment = var.environment
  }
}

# Log Analytics Workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "monitoring-logs-${var.environment}"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "monitoring" {
  name                = "monitoring-aks-${var.environment}"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  dns_prefix          = "monitoring-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = true
    min_count           = var.min_node_count
    max_count           = var.max_node_count
    max_pods            = 110

    tags = {
      Environment = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  }

  azure_policy_enabled = true

  http_application_routing_enabled = false

  tags = {
    Environment = var.environment
  }
}

# Role assignment for ACR (if created)
resource "azurerm_role_assignment" "aks_acr" {
  count                = var.create_acr ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.monitoring.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.monitoring[0].id
}

# Azure Storage Account for persistent volumes
resource "azurerm_storage_account" "monitoring" {
  name                     = "monitoringst${var.environment}"
  resource_group_name      = azurerm_resource_group.monitoring.name
  location                 = azurerm_resource_group.monitoring.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    Environment = var.environment
  }
}

# Azure Files Storage for persistent volumes
resource "azurerm_storage_share" "prometheus" {
  name                 = "prometheus-data"
  storage_account_name = azurerm_storage_account.monitoring.name
  quota                = 100
}

resource "azurerm_storage_share" "grafana" {
  name                 = "grafana-data"
  storage_account_name = azurerm_storage_account.monitoring.name
  quota                = 50
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.monitoring.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.monitoring.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.monitoring.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.monitoring.kube_config[0].cluster_ca_certificate)
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.monitoring.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.monitoring.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.monitoring.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.monitoring.kube_config[0].cluster_ca_certificate)
  }
}

# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.monitoring]
}

# Deploy monitoring stack using Helm
resource "helm_release" "monitoring" {
  name       = "monitoring"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  chart      = "../../kubernetes/helm/monitoring"

  set {
    name  = "prometheus.replicas"
    value = var.prometheus_replicas
  }

  set {
    name  = "grafana.replicas"
    value = var.grafana_replicas
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Azure Monitor integration
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.monitoring.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
