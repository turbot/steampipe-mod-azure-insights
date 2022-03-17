dashboard "azure_compute_disk_encryption_report" {

  title         = "Azure Compute Disk Encryption Report"
  documentation = file("./dashboards/compute/docs/compute_disk_report_encryption.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.azure_compute_disk_count
      width = 2
    }

    card {
      query = query.azure_compute_disk_platform_managed_encryption_count
      width = 2
    }

    card {
      query = query.azure_compute_disk_customer_managed_encryption_count
      width = 2
    }

    card {
      query = query.azure_compute_disk_cmk_and_platfrom_managed_encryption_count
      width = 2
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    column "Subscription ID" {
      display = "none"
    }

    query = query.azure_compute_disk_encryption_report
  }

}

query "azure_compute_disk_encryption_report" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.unique_id as "Unique ID",
      d.id as "ID",
      d.encryption_type as "Encryption Type",
      d.encryption_disk_encryption_set_id as "Disk Encryption Set ID",
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

query "azure_compute_disk_platform_managed_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Platform-Managed Encryption' as label
    from
      azure_compute_disk
    where
      encryption_type = 'EncryptionAtRestWithPlatformKey';
  EOQ
}

query "azure_compute_disk_customer_managed_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Customer-Managed Encryption' as label
    from
      azure_compute_disk
    where
      encryption_type = 'EncryptionAtRestWithCustomerKey';
  EOQ
}

query "azure_compute_disk_cmk_and_platfrom_managed_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Platform And Customer-Managed Encryption' as label
    from
      azure_compute_disk
    where
      encryption_type = 'EncryptionAtRestWithPlatformAndCustomerKeys';
  EOQ
}
