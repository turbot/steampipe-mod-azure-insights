dashboard "azure_compute_disk_age_report" {

  title  = "Azure Compute Disk Age Report"

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.azure_compute_disk_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_compute_disk_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_compute_disk_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_compute_disk_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.azure_compute_disk_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.azure_compute_disk_1_year_count
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    column "Subscription ID" {
      display = "none"
    }

    query = query.azure_compute_disk_age_table
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
      d.subscription_id as "Subscription ID",
      sub.title as "Subscription",
      d.region as "Region",
      d.resource_group as "Resource Group"
    from
      azure_compute_disk as d,
      azure_subscription as sub
    where
      d.subscription_id = sub.subscription_id
    order by
      d.name;
  EOQ
}