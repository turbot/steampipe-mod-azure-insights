dashboard "network_virtual_network_inventory_report" {

  title         = "Azure Virtual Network Inventory Report"
  documentation = file("./dashboards/network/docs/network_virtual_network_report_inventory.md")

  tags = merge(local.network_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.virtual_network_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.network_virtual_network_detail.url_path}?input.vnet_id={{.'ID' | @uri}}"
    }

    query = query.network_virtual_network_inventory_table
  }
}

query "network_virtual_network_inventory_table" {
  sql = <<-EOQ
    select
      v.name as "Name",
      v.address_prefixes as "Address Prefixes",
      v.enable_ddos_protection as "Enable DDoS Protection",
      v.enable_vm_protection as "Enable VM Protection",
      v.provisioning_state as "Provisioning State",
      v.resource_guid as "Resource GUID",
      v.subnets as "Subnets",
      v.network_peerings as "Network Peerings",
      v.tags as "Tags",
      v.id as "ID",
      sub.title as "Subscription",
      v.subscription_id as "Subscription ID",
      v.resource_group as "Resource Group",
      v.region as "Region"
    from
      azure_virtual_network as v,
      azure_subscription as sub
    where
      v.subscription_id = sub.subscription_id
    order by
      v.name;
  EOQ
} 