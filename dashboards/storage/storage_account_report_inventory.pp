dashboard "storage_account_inventory_report" {

  title         = "Azure Storage Account Inventory Report"
  documentation = file("./dashboards/storage/docs/storage_account_report_inventory.md")

  tags = merge(local.storage_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.storage_account_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.storage_account_detail.url_path}?input.storage_account_id={{.ID | @uri}}"
    }

    query = query.storage_account_inventory_table
  }
}

query "storage_account_inventory_table" {
  sql = <<-EOQ
    select
      s.name as "Name",
      s.creation_time as "Creation Time",
      s.kind as "Kind",
      s.sku_name as "SKU Name",
      s.sku_tier as "SKU Tier",
      s.access_tier as "Access Tier",
      s.enable_https_traffic_only as "Enable HTTPS Traffic Only",
      s.is_hns_enabled as "Hierarchical Namespace Enabled",
      s.network_rule_default_action as "Network Rule Default Action",
      s.require_infrastructure_encryption as "Infrastructure Encryption Required",
      s.allow_blob_public_access as "Allow Blob Public Access",
      s.minimum_tls_version as "Minimum TLS Version",
      s.tags as "Tags",
      lower(s.id) as "ID",
      sub.title as "Subscription",
      s.subscription_id as "Subscription ID",
      s.resource_group as "Resource Group",
      s.region as "Region"
    from
      azure_storage_account as s,
      azure_subscription as sub
    where
      s.subscription_id = sub.subscription_id
    order by
      s.name;
  EOQ
} 