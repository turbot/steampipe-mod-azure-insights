dashboard "azure_storage_account_age_report" {

  title         = "Azure Storage Account Age Report"
  documentation = file("./dashboards/storage/docs/storage_account_report_age.md")

  tags = merge(local.storage_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      query = query.azure_storage_account_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_storage_account_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_storage_account_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_storage_account_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.azure_storage_account_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.azure_storage_account_1_year_count
    }

  }

  table {
    column "Subscription ID" {
      display = "none"
    }

    column "ID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.azure_storage_account_detail.url_path}?input.id={{.ID | @uri}}"
    }

    query = query.azure_storage_account_age_table
  }

}

query "azure_storage_account_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azure_storage_account
    where
      creation_time > now() - '1 days' :: interval;
  EOQ
}

query "azure_storage_account_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      azure_storage_account
    where
      creation_time between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "azure_storage_account_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      azure_storage_account
    where
      creation_time between symmetric now() - '30 days' :: interval
      and now() - '90 days' :: interval;
  EOQ
}

query "azure_storage_account_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azure_storage_account
    where
      creation_time between symmetric (now() - '90 days'::interval)
      and (now() - '365 days'::interval);
  EOQ
}

query "azure_storage_account_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azure_storage_account
    where
      creation_time <= now() - '1 year' :: interval;
  EOQ
}

query "azure_storage_account_age_table" {
  sql = <<-EOQ
    select
      a.name as "Name",
      now()::date - a.creation_time::date as "Age in Days",
      a.creation_time as "Create Time",
      a.kind as "Kind",
      sub.title as "Subscription",
      a.subscription_id as "Subscription ID",
      a.resource_group as "Resource Group",
      a.region as "Region",
      a.id as "ID"
    from
      azure_storage_account as a,
      azure_subscription as sub
    where
      a.subscription_id = sub.subscription_id
    order by
      a.name;
  EOQ
}
