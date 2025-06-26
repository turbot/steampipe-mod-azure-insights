dashboard "kubernetes_cluster_inventory_report" {

  title         = "Azure Kubernetes Cluster Inventory Report"
  documentation = file("./dashboards/kubernetes/docs/kubernetes_cluster_report_inventory.md")

  tags = merge(local.kubernetes_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.kubernetes_cluster_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.kubernetes_cluster_detail.url_path}?input.cluster_id={{.'ID' | @uri}}"
    }

    query = query.kubernetes_cluster_inventory_table
  }
}

query "kubernetes_cluster_inventory_table" {
  sql = <<-EOQ
    select
      k.name as "Name",
      k.provisioning_state as "Provisioning State",
      k.kubernetes_version as "Kubernetes Version",
      k.dns_prefix as "DNS Prefix",
      k.enable_rbac as "RBAC Enabled",
      k.enable_pod_security_policy as "Pod Security Policy Enabled",
      k.max_agent_pools as "Max Agent Pools",
      k.power_state ->> 'code' as "Power State",
      k.sku ->> 'name' as "SKU",
      k.tags as "Tags",
      lower(k.id) as "ID",
      sub.title as "Subscription",
      k.subscription_id as "Subscription ID",
      k.resource_group as "Resource Group",
      k.region as "Region"
    from
      azure_kubernetes_cluster as k,
      azure_subscription as sub
    where
      sub.subscription_id = k.subscription_id
    order by
      k.name;
  EOQ
} 