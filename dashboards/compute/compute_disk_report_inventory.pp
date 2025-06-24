dashboard "compute_disk_report_inventory" {

  title         = "Azure Compute Disk Inventory Report"
  documentation = file("./dashboards/compute/docs/compute_disk_report_inventory.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.compute_disk_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.compute_disk_detail.url_path}?input.disk_id={{.'ID' | @uri}}"
    }

    query = query.compute_disk_inventory_table
  }

}

query "compute_disk_inventory_table" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.disk_state as "State",
      d.disk_size_gb as "Size (GB)",
      d.sku_name as "SKU",
      d.managed_by as "Managed By",
      d.encryption_settings_collection_enabled as "Encryption Enabled",
      d.os_type as "OS Type",
      d.network_access_policy as "Network Access",
      d.public_network_access as "Public Access",
      d.tags as "Tags",
      lower(d.id) as "ID",
      sub.title as "Subscription",
      d.subscription_id as "Subscription ID",
      d.resource_group as "Resource Group",
      d.region as "Region"
    from
      azure_compute_disk as d,
      azure_subscription as sub
    where
      sub.subscription_id = d.subscription_id
    order by
      d.name;
  EOQ
} 