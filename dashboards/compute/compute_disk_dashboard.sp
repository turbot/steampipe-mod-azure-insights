dashboard "azure_compute_disk_dashboard" {

  title = "Azure Compute Disk Dashboard"

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.azure_compute_disk_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_disk_storage_total.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.azure_compute_disk_unattached_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Attached With Network"
      sql   = query.azure_compute_disk_by_attachment.sql
      type  = "donut"
      width = 2

      series "count" {
        point "attached" {
          color = "ok"
        }
        point "unattached" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Disks by Subscription"
      sql   = query.azure_compute_disk_by_subscription.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Disks by Resource Group"
      sql   = query.azure_compute_disk_by_resource_group.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Disks by Region"
      sql   = query.azure_compute_disk_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Disks by Encryption Type"
      sql   = query.azure_compute_disk_by_encryption_type.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Disks by OS Type"
      sql   = query.azure_compute_disk_by_os_type.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Disks by SKU"
      sql   = query.azure_compute_disk_by_sku_tier.sql
      type  = "column"
      width = 4
    }
  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 Average Read IOPS - Last 7 days"
      sql   = query.azure_compute_disk_top_10_read_ops_avg.sql
      type  = "line"
      width = 6
    }

    chart {
      title = "Top 10 Average Write IOPS - Last 7 days"
      sql   = query.azure_compute_disk_top_10_write_ops_avg.sql
      type  = "column"
      width = 6
    }

  }
}

# Card Queries

query "azure_compute_disk_count" {
  sql = <<-EOQ
    select count(*) as "Disks" from azure_compute_disk;
  EOQ
}

query "azure_compute_disk_storage_total" {
  sql = <<-EOQ
    select
      sum(disk_size_gb) as "Total Storage (GB)"
    from
      azure_compute_disk;
  EOQ
}


query "azure_compute_disk_unattached_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unattached' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_compute_disk
    where
      disk_state = 'Unattached';
  EOQ
}

# Assessment Queries

query "azure_compute_disk_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption,
      count(*)
    from (
      select encryption_type,
        case when encryption_type in
          ('EncryptionAtRestWithPlatformKey', 'EncryptionAtRestWithCustomerKey', 'EncryptionAtRestWithPlatformAndCustomerKeys')
        then
          'encrypted'
        else
          'unencrypted'
        end encryption
      from
        azure_compute_disk) as cd
    group by
      encryption
    order by
      encryption;
  EOQ
}

query "azure_compute_disk_by_attachment" {
  sql = <<-EOQ
    select
      attachment,
      count(*)
    from (
      select disk_state,
        case when disk_state = 'Unattached' then
          'unattached'
        else
          'attached'
        end attachment
      from
        azure_compute_disk) as cd
    group by
      attachment
    order by
      attachment;
  EOQ
}

# Analysis Queries

query "azure_compute_disk_by_subscription" {
  sql = <<-EOQ
    select
      a.title as "Subscription",
      count(v.*) as "Disks"
    from
      azure_compute_disk as v,
      azure_subscription as a
    where
      a.subscription_id = v.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "azure_compute_disk_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(resource_group) as "Accounts"
    from
      azure_compute_disk as d,
      azure_subscription as sub
    where
       d.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_compute_disk_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Disks" from azure_compute_disk group by region order by region;
  EOQ
}

query "azure_compute_disk_by_encryption_type" {
  sql = <<-EOQ
    select
      encryption_type as "Type",
      count(os_type) as "Disks"
    from
      azure_compute_disk
    group by
      encryption_type
    order by
      encryption_type;
  EOQ
}

query "azure_compute_disk_by_os_type" {
  sql = <<-EOQ
    select
      os_type as "Type",
      count(os_type) as "Disks"
    from
      azure_compute_disk
    group by
      os_type
    order by
      os_type;
  EOQ
}

query "azure_compute_disk_by_sku_tier" {
  sql = <<-EOQ
    select
      sku_tier as "SKU Tier",
      count(sku_tier) as "Disks"
    from
      azure_compute_disk
    group by
      sku_tier
    order by
      sku_tier;
  EOQ
}

query "azure_compute_disk_top_10_read_ops_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        name,
        resource_group,
        avg(average)
      from
        azure_compute_disk_metric_read_ops_daily
      where
        timestamp >= CURRENT_DATE - INTERVAL '7 day'
      group by
        name,
        resource_group
      order by
        avg desc
      limit 10
    )
    select
      timestamp,
      name,
      average
    from
      azure_compute_disk_metric_read_ops_hourly
    where
      timestamp >= CURRENT_DATE - INTERVAL '7 day'
      and name in (select name from top_n group by name, resource_group)
    order by
      timestamp;
  EOQ
}

query "azure_compute_disk_top_10_write_ops_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        name,
        resource_group,
        avg(average)
      from
        azure_compute_disk_metric_write_ops_daily
      where
        timestamp >= CURRENT_DATE - INTERVAL '7 day'
      group by
        name,
        resource_group
      order by
        avg desc
      limit 10
    )
    select
      timestamp,
      name,
      average
    from
      azure_compute_disk_metric_write_ops_hourly
    where
      timestamp >= CURRENT_DATE - INTERVAL '7 day'
      and name in (select name from top_n group by name, resource_group)
    order by
      timestamp desc;
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
