dashboard "azure_compute_disk_encryption_report" {

  title  = "Azure Compute Disk Encryption Report"

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.azure_compute_disk_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_disk_platform_managed_encryption_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_disk_customer_managed_encryption_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_disk_cmk_and_platfrom_managed_encryption_count.sql
      width = 2
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    sql = query.azure_compute_disk_encryption_report.sql
  }

}

query "azure_compute_disk_encryption_report" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.unique_id as "Unique ID",
      d.id as "ID",
      d.encryption_type as "Encryption Type",
      d.disk_state as "Disk State",
      d.region as "Region",
      d.resource_group as "Resource Group",
      d.subscription_id as "Subscription ID"
    from
      azure_compute_disk as d,
      azure_subscription sub
    where
      sub.subscription_id = d.subscription_id;
  EOQ
}
