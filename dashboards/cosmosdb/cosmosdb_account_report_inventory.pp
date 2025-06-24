dashboard "cosmosdb_account_inventory_report" {

  title         = "Azure Cosmos DB Account Inventory Report"
  documentation = file("./dashboards/cosmosdb/docs/cosmosdb_account_report_inventory.md")

  tags = merge(local.cosmosdb_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.cosmosdb_account_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.cosmosdb_account_detail.url_path}?input.account_id={{.'ID' | @uri}}"
    }

    query = query.cosmosdb_account_inventory_table
  }
}

query "cosmosdb_account_inventory_table" {
  sql = <<-EOQ
    select
      c.name as "Name",
      c.kind as "Kind",
      c.provisioning_state as "Provisioning State",
      c.default_consistency_level as "Default Consistency Level",
      c.enable_automatic_failover as "Enable Automatic Failover",
      c.enable_multiple_write_locations as "Enable Multiple Write Locations",
      c.enable_analytical_storage as "Enable Analytical Storage",
      c.public_network_access as "Public Network Access",
      c.is_virtual_network_filter_enabled as "Is Virtual Network Filter Enabled",
      jsonb_array_length(c.locations) as "Locations",
      c.tags as "Tags",
      lower(c.id) as "ID",
      sub.title as "Subscription",
      c.subscription_id as "Subscription ID",
      c.resource_group as "Resource Group",
      c.region as "Region"
    from
      azure_cosmosdb_account as c,
      azure_subscription as sub
    where
      sub.subscription_id = c.subscription_id
    order by
      c.name;
  EOQ
} 