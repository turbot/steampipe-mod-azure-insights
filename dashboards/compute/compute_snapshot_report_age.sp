dashboard "compute_snapshot_age_report" {

  title         = "Azure Compute Snapshot Age Report"
  documentation = file("./dashboards/compute/docs/compute_snapshot_report_age.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.compute_snapshot_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_snapshot_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_snapshot_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_snapshot_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.compute_snapshot_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.compute_snapshot_1_year_count
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    column "Subscription ID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.compute_snapshot_detail.url_path}?input.id={{.ID | @uri}}"
    }

    query = query.compute_snapshot_age_table
  }

}

query "compute_snapshot_24_hours_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azure_compute_snapshot
    where
      time_created > now() - '1 days' :: interval
      and name <> 'master';
  EOQ
}

query "compute_snapshot_30_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      azure_compute_snapshot
    where
      time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
      and name <> 'master';
  EOQ
}

query "compute_snapshot_30_90_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      azure_compute_snapshot
    where
      time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
      and name <> 'master';
  EOQ
}

query "compute_snapshot_90_365_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azure_compute_snapshot
    where
      time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
      and name <> 'master';
  EOQ
}

query "compute_snapshot_1_year_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azure_compute_snapshot
    where
      time_created <= now() - '1 year' :: interval
      and name <> 'master';
  EOQ
}

query "compute_snapshot_age_table" {
  sql = <<-EOQ
    select
      s.name as "Name",
      s.unique_id as "Unique ID",
      now()::date - s.time_created::date as "Age in Days",
      s.time_created as "Time Created",
      sub.title as "Subscription",
      s.subscription_id as "Subscription ID",
      s.resource_group as "Resource Group",
      s.region as "Region",
      lower(s.id) as "ID"
    from
      azure_compute_snapshot as s,
      azure_subscription as sub
    where
      s.subscription_id = sub.subscription_id
    order by
      s.name;
  EOQ
}