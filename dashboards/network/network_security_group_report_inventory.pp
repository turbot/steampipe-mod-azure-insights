dashboard "network_security_group_inventory_report" {

  title         = "Azure Network Security Group Inventory Report"
  documentation = file("./dashboards/network/docs/network_security_group_report_inventory.md")

  tags = merge(local.network_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.network_security_group_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.network_security_group_detail.url_path}?input.nsg_id={{.'ID' | @uri}}"
    }

    query = query.network_security_group_inventory_table
  }
}

query "network_security_group_inventory_table" {
  sql = <<-EOQ
    select
      n.name as "Name",
      n.provisioning_state as "Provisioning State",
      jsonb_array_length(n.security_rules) as "Security Rules",
      jsonb_array_length(n.default_security_rules) as "Default Security Rules",
      jsonb_array_length(n.network_interfaces) as "Network Interfaces",
      jsonb_array_length(n.subnets) as "Subnets",
      jsonb_array_length(n.flow_logs) as "Flow Logs",
      n.tags as "Tags",
      lower(n.id) as "ID",
      sub.title as "Subscription",
      n.subscription_id as "Subscription ID",
      n.resource_group as "Resource Group",
      n.region as "Region"
    from
      azure_network_security_group as n,
      azure_subscription as sub
    where
      sub.subscription_id = n.subscription_id
    order by
      n.name;
  EOQ
} 