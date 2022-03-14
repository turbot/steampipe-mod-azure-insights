dashboard "azure_compute_disk_age_report" {

  title  = "Azure Compute Disk Age Report"

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.azure_compute_disk_count.sql
      width = 2
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_compute_disk_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_compute_disk_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_compute_disk_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.azure_compute_disk_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.azure_compute_disk_1_year_count.sql
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    sql = query.azure_compute_disk_age_table.sql
  }

}

query "azure_compute_disk_24_hours_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azure_compute_disk
    where
      time_created > now() - '1 days' :: interval
      and name <> 'master';
  EOQ
}

query "azure_compute_disk_30_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      azure_compute_disk
    where
      time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
      and name <> 'master';
  EOQ
}

query "azure_compute_disk_30_90_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      azure_compute_disk
    where
      time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
      and name <> 'master';
  EOQ
}

query "azure_compute_disk_90_365_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azure_compute_disk
    where
      time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
      and name <> 'master';
  EOQ
}

query "azure_compute_disk_1_year_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azure_compute_disk
    where
      time_created <= now() - '1 year' :: interval
      and name <> 'master';
  EOQ
}

query "azure_compute_disk_age_table" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.unique_id as "Unique ID",
      d.id as "ID",
      now()::date - d.time_created::date as "Age in Days",
      d.time_created as "Create Date",
      d.disk_state as "Disk State",
      d.region as "Region",
      d.resource_group as "Resource Group",
      d.subscription_id as "Subscription ID"
    from
      azure_compute_disk as d
    order by
      d.name;
  EOQ
}