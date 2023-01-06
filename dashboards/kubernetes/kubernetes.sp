locals {
  kubernetes_common_tags = {
    service = "Azure/Kubernetes"
  }
}

category "kubernetes_cluster" {
  title = "Kubernetes Clusters"
  color = local.containers_color
  href  = "/azure_insights.dashboard.kubernetes_cluster_detail?input.cluster_id={{.properties.'ID' | @uri}}"
  icon  = "hub"
}

category "kubernetes_node_pool" {
  title = "Kubernetes Node Pools"
  color = local.containers_color
  icon  = "device_hub"
}
