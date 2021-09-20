output "id" {
  description = "The Kubernetes Managed Cluster ID."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "client_certificate" {
  description = "The Kubernetes certificate."
  value = azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate
}

output "client_key" {
  description = "The Kubernetes client key"
  value = azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key
}

output "client_ca_certificate" {
  description = "The Kubernetes client CA certificate"
  value = azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate
}

output "host" {
  description = "The Kubernetes cluster server host."
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
}
