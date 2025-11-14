# Azure AKS Deployment Outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.monitoring.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.monitoring.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.monitoring.id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.monitoring.fqdn
}

output "aks_node_resource_group" {
  description = "Resource group containing AKS nodes"
  value       = azurerm_kubernetes_cluster.monitoring.node_resource_group
}

output "kube_config" {
  description = "Kubernetes config for connecting to the cluster"
  value       = azurerm_kubernetes_cluster.monitoring.kube_config_raw
  sensitive   = true
}

output "acr_login_server" {
  description = "Login server for Azure Container Registry"
  value       = var.create_acr ? azurerm_container_registry.monitoring[0].login_server : null
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.monitoring.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.monitoring.name
}

output "storage_account_name" {
  description = "Name of the storage account for persistent volumes"
  value       = azurerm_storage_account.monitoring.name
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.monitoring.name} --name ${azurerm_kubernetes_cluster.monitoring.name}"
}

output "grafana_access_command" {
  description = "Command to access Grafana"
  value       = "kubectl port-forward -n monitoring svc/grafana 3000:3000"
}

output "prometheus_access_command" {
  description = "Command to access Prometheus"
  value       = "kubectl port-forward -n monitoring svc/prometheus 9090:9090"
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    environment            = var.environment
    location               = var.location
    aks_cluster            = azurerm_kubernetes_cluster.monitoring.name
    kubernetes_version     = azurerm_kubernetes_cluster.monitoring.kubernetes_version
    node_count             = var.node_count
    prometheus_replicas    = var.prometheus_replicas
    grafana_replicas       = var.grafana_replicas
    log_analytics_enabled  = true
  }
}
