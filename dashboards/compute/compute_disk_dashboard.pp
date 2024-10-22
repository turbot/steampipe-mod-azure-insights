dashboard "compute_disk_dashboard" {

  title         = "Azure Compute Disk Dashboard"
  documentation = file("./dashboards/compute/docs/compute_disk_dashboard.md")

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.compute_disk_count
      width = 3
    }

    card {
      query = query.compute_disk_storage_total
      width = 3
    }

    # Assessments
    card {
      query = query.compute_disk_unattached_count
      width = 3
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Attached With Network"
      query = query.compute_disk_by_attachment
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
      query = query.compute_disk_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by Resource Group"
      query = query.compute_disk_by_resource_group
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by Region"
      query = query.compute_disk_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by Age"
      query = query.compute_disk_by_age
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by Encryption Type"
      query = query.compute_disk_by_encryption_type
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by OS Type"
      query = query.compute_disk_by_os_type
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by SKU Tier"
      query = query.compute_disk_by_sku_tier
      type  = "column"
      width = 3
    }

  }

  container {
    chart {
      title = "Storage by Subscription (GB)"
      sql   = query.compute_disk_storage_by_subscription.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Resource Group (GB)"
      sql   = query.compute_disk_storage_by_resource_group.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      sql   = query.compute_disk_storage_by_region.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      sql   = query.compute_disk_storage_by_age.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }
  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 Average Read IOPS - Last 7 days"
      query = query.compute_disk_top_10_read_ops_avg
      type  = "line"
      width = 6
    }

    chart {
      title = "Top 10 Average Write IOPS - Last 7 days"
      query = query.compute_disk_top_10_write_ops_avg
      type  = "column"
      width = 6
    }

  }

}

# Card Queries

query "compute_disk_count" {
  sql = <<-EOQ
    select count(*) as "Disks" from azure_compute_disk;
  EOQ
}

query "compute_disk_storage_total" {
  sql = <<-EOQ
    select
      sum(disk_size_gb) as "Total Storage (GB)"
    from
      azure_compute_disk;
  EOQ
}

query "compute_disk_unattached_count" {
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

query "compute_disk_by_attachment" {
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

query "compute_disk_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(d.*) as "Disks"
    from
      azure_compute_disk as d,
      azure_subscription as sub
    where
      sub.subscription_id = d.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "compute_disk_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(d.*) as "Disks"
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

query "compute_disk_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Disks"
    from
      azure_compute_disk
    group by
      region
    order by
      region;
  EOQ
}

query "compute_disk_by_age" {
  sql = <<-EOQ
    with disks as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        azure_compute_disk
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(time_created)
                from disks)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    disks_by_month as (
      select
        creation_month,
        count(*)
      from
        disks
      group by
        creation_month
    )
    select
      months.month,
      disks_by_month.count
    from
      months
      left join disks_by_month on months.month = disks_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "compute_disk_by_encryption_type" {
  sql = <<-EOQ
    select
      encryption_type as "Encryption Type",
      count(os_type) as "Disks"
    from
      azure_compute_disk
    group by
      encryption_type
    order by
      encryption_type;
  EOQ
}

query "compute_disk_by_os_type" {
  sql = <<-EOQ
    select
      os_type as "OS Type",
      count(os_type) as "Disks"
    from
      azure_compute_disk
    group by
      os_type
    order by
      os_type;
  EOQ
}

query "compute_disk_by_sku_tier" {
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

query "compute_disk_storage_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      sum(d.disk_size_gb) as "GB"
    from
      azure_compute_disk as d,
      azure_subscription as sub
    where
      sub.subscription_id = d.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "compute_disk_storage_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      sum(d.disk_size_gb) as "GB"
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

query "compute_disk_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(disk_size_gb) as "GB"
    from
      azure_compute_disk
    group by
      region
    order by
      region;
  EOQ
}

query "compute_disk_storage_by_age" {
  sql = <<-EOQ
    with disks as (
      select
        title,
        disk_size_gb,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        azure_compute_disk
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
          (
            select
              min(time_created)
              from disks)),
          date_trunc('month',
            current_date),
          interval '1 month') as d
        ),
      disks_by_month as (
        select
          creation_month,
          sum(disk_size_gb) as size
        from
          disks
        group by
          creation_month
    )
    select
      months.month,
      disks_by_month.size as "GB"
    from
      months
      left join disks_by_month on months.month = disks_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "compute_disk_top_10_read_ops_avg" {
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

query "compute_disk_top_10_write_ops_avg" {
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
