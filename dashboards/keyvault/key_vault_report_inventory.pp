dashboard "key_vault_inventory_report" {

  title         = "Azure Key Vault Inventory Report"
  documentation = file("./dashboards/keyvault/docs/key_vault_report_inventory.md")

  tags = merge(local.keyvault_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.key_vault_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.key_vault_detail.url_path}?input.key_vault_id={{.'ID' | @uri}}"
    }

    query = query.key_vault_inventory_table
  }
}

query "key_vault_inventory_table" {
  sql = <<-EOQ
    select
      k.name as "Name",
      k.vault_uri as "Vault URI",
      k.sku_name as "SKU Name",
      k.enabled_for_deployment as "Enabled for Deployment",
      k.enabled_for_disk_encryption as "Enabled for Disk Encryption",
      k.enabled_for_template_deployment as "Enabled for Template Deployment",
      k.enable_rbac_authorization as "Enable RBAC Authorization",
      k.purge_protection_enabled as "Purge Protection Enabled",
      k.soft_delete_enabled as "Soft Delete Enabled",
      k.soft_delete_retention_in_days as "Soft Delete Retention Days",
      k.network_acls ->> 'defaultAction' as "Network Default Action",
      k.tags as "Tags",
      lower(k.id) as "ID",
      sub.title as "Subscription",
      k.subscription_id as "Subscription ID",
      k.resource_group as "Resource Group",
      k.region as "Region"
    from
      azure_key_vault as k,
      azure_subscription as sub
    where
      k.subscription_id = sub.subscription_id
    order by
      k.name;
  EOQ
} 