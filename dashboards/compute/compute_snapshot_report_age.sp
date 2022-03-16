dashboard "azure_compute_snapshot_age_report" {

  title  = "Azure Compute Snapshot Age Report"

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.azure_compute_snapshot_count.sql
      width = 2
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_compute_snapshot_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_compute_snapshot_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_compute_snapshot_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.azure_compute_snapshot_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.azure_compute_snapshot_1_year_count.sql
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    column "Subscription ID" {
      display = "none"
    }
    
    sql = query.azure_compute_snapshot_age_table.sql
  }

}

query "azure_compute_snapshot_24_hours_count" {
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

query "azure_compute_snapshot_30_days_count" {
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

query "azure_compute_snapshot_30_90_days_count" {
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

query "azure_compute_snapshot_90_365_days_count" {
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

query "azure_compute_snapshot_1_year_count" {
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

query "azure_compute_snapshot_age_table" {
  sql = <<-EOQ
    select
      s.name as "Name",
      s.unique_id as "Unique ID",
      s.id as "ID",
      now()::date - s.time_created::date as "Age in Days",
      s.time_created as "Create Date",
      s.subscription_id as "Subscription ID",
      sub.title as "Subscription",
      s.region as "Region",
      s.resource_group as "Resource Group"
    from
      azure_compute_snapshot as s,
      azure_subscription as sub
    where
      s.subscription_id = sub.subscription_id
    order by
      s.name;
  EOQ
}