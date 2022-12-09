locals {
  kubernetes_common_tags = {
    service = "Azure/Kubernetes"
  }
}

category "kubernetes_cluster" {
  title = "Kubernetes Clusters"
  href  = "/azure_insights.dashboard.kubernetes_cluster_detail?input.cluster_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:cog"
  color = local.containers_color
}

category "kubernetes_node_pool" {
  title = "Kubernetes Node Pools"
  icon  = "text:NodePool"
  color = local.containers_color
}
