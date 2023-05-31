dashboard "compute_disk_age_report" {

  title         = "Azure Compute Disk Age Report"
  documentation = file("./dashboards/compute/docs/compute_disk_report_age.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.compute_disk_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_disk_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_disk_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_disk_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.compute_disk_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.compute_disk_1_year_count
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
      href = "${dashboard.compute_disk_detail.url_path}?input.disk_id={{.ID | @uri}}"
    }

    query = query.compute_disk_age_table
  }

}

query "compute_disk_24_hours_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azure_compute_disk
    where
      time_created > now() - '1 days' :: interval;
  EOQ
}

query "compute_disk_30_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      azure_compute_disk
    where
      time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "compute_disk_30_90_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      azure_compute_disk
    where
      time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "compute_disk_90_365_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azure_compute_disk
    where
      time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "compute_disk_1_year_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azure_compute_disk
    where
      time_created <= now() - '1 year' :: interval;
  EOQ
}

query "compute_disk_age_table" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.unique_id as "Unique ID",
      now()::date - d.time_created::date as "Age in Days",
      d.time_created as "Time Created",
      d.disk_state as "Disk State",
      sub.title as "Subscription",
      d.subscription_id as "Subscription ID",
      d.resource_group as "Resource Group",
      d.region as "Region",
      lower(d.id) as "ID"
    from
      azure_compute_disk as d,
      azure_subscription as sub
    where
      d.subscription_id = sub.subscription_id
    order by
      d.name;
  EOQ
}
