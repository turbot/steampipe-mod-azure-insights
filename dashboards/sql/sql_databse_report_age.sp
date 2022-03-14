dashboard "azure_sql_database_age_report" {

  title  = "Azure SQL Database Age Report"

  tags = merge(local.sql_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.azure_sql_database_count.sql
      width = 2
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_sql_database_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_sql_database_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.azure_sql_database_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.azure_sql_database_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.azure_sql_database_1_year_count.sql
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    sql = query.azure_sql_database_age_table.sql
  }

}

query "azure_sql_database_24_hours_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azure_sql_database
    where
      creation_date > now() - '1 days' :: interval
      and name <> 'master';
  EOQ
}

query "azure_sql_database_30_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      azure_sql_database
    where
      creation_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
      and name <> 'master';
  EOQ
}

query "azure_sql_database_30_90_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      azure_sql_database
    where
      creation_date between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
      and name <> 'master';
  EOQ
}

query "azure_sql_database_90_365_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azure_sql_database
    where
      creation_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
      and name <> 'master';
  EOQ
}

query "azure_sql_database_1_year_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azure_sql_database
    where
      creation_date <= now() - '1 year' :: interval
      and name <> 'master';
  EOQ
}

query "azure_sql_database_age_table" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.database_id as "Database ID",
      now()::date - d.creation_date::date as "Age in Days",
      d.creation_date as "Create Date",
      d.status as "Status",
      d.region as "Region",
      d.resource_group as "Resource Group",
      d.subscription_id as "Subscription ID"
    from
      azure_sql_database as d
    where
      d.name <> 'master'
    order by
      d.name;
  EOQ
}