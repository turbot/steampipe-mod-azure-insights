dashboard "compute_virtual_machine_inventory_report" {

  title         = "Azure Virtual Machine Inventory Report"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_report_inventory.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.compute_virtual_machine_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.compute_virtual_machine_detail.url_path}?input.vm_id={{.ID | @uri}}"
    }

    query = query.compute_virtual_machine_inventory_table
  }
}

query "compute_virtual_machine_inventory_table" {
  sql = <<-EOQ
    select
      v.name as "Name",
      v.time_created as "Time Created",
      v.size as "Size",
      v.os_type as "OS Type",
      v.os_name as "OS Name",
      v.os_version as "OS Version",
      v.power_state as "Power State",
      v.provisioning_state as "Provisioning State",
      v.admin_user_name as "Admin Username",
      v.priority as "Priority",
      v.computer_name as "Computer Name",
      v.enable_automatic_updates as "Enable Automatic Updates",
      v.ultra_ssd_enabled as "Ultra SSD Enabled",
      v.network_interfaces as "Network Interfaces",
      v.extensions as "Extensions",
      v.tags as "Tags",
      lower(v.id)as "ID",
      sub.title as "Subscription",
      v.subscription_id as "Subscription ID",
      v.resource_group as "Resource Group",
      v.region as "Region"
    from
      azure_compute_virtual_machine as v,
      azure_subscription as sub
    where
      v.subscription_id = sub.subscription_id
    order by
      v.name;
  EOQ
} 