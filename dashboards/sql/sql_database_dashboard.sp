dashboard "azure_sql_database_dashboard" {

  title         = "Azure SQL Database Dashboard"
  documentation = file("./dashboards/sql/docs/sql_database_dashboard.md")

  tags = merge(local.sql_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.azure_sql_database_count
      width = 2
    }

    card {
      query = query.azure_sql_database_transparent_data_encryption_disabled_count
      width = 2
    }

    card {
      query = query.azure_sql_database_vulnerability_assessment_disabled_count
      width = 2
    }

    card {
      query = query.azure_sql_database_geo_redundant_backup_disabled_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "TDE Status"
      query = query.azure_sql_database_tde_status
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Vulnerability Assessment Status"
      query = query.azure_sql_database_vulnerability_assessment_status
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Geo-Redundant Backup Status"
      query = query.azure_sql_database_geo_redundant_backup_status
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Databases by Subscription"
      query = query.azure_sql_database_by_subscription
      type  = "column"
      width = 4
    }

    chart {
      title = "Databases by Resource Group"
      query = query.azure_sql_database_by_resource_group
      type  = "column"
      width = 4
    }

    chart {
      title = "Databases by Age"
      query = query.azure_sql_database_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Databases by Region"
      query = query.azure_sql_database_by_region
      type  = "column"
      width = 4
    }


    chart {
      title = "Databases by Status"
      query = query.azure_sql_database_by_status
      type  = "column"
      width = 4
    }

    chart {
      title = "Databases by Edition"
      query = query.azure_sql_database_by_edition
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "azure_sql_database_count" {
  sql = <<-EOQ
    select count(*) as "Databases" from azure_sql_database where name <> 'master';
  EOQ
}

query "azure_sql_database_transparent_data_encryption_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'TDE Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_sql_database
    where
      transparent_data_encryption ->> 'status' <> 'Enabled'
      and name <> 'master';
  EOQ
}

query "azure_sql_database_vulnerability_assessment_disabled_count" {
  sql = <<-EOQ
    with sql_database_va as (
      select
        distinct id
      from
        azure_sql_database as s,
        jsonb_array_elements(vulnerability_assessments) as va
      where
        va -> 'properties' -> 'recurringScans' ->> 'isEnabled' = 'true'
    )
    select
      count(*) as value,
      'Vulnerability Assessment Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
     azure_sql_database as d where d.id not in (select id from sql_database_va)
     and d.name <> 'master';
  EOQ
}

query "azure_sql_database_geo_redundant_backup_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Geo-Redundant Backup Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_sql_database
    where
      not (retention_policy_property ->> 'monthlyRetention' <> 'PT0S'
      or retention_policy_property ->> 'weeklyRetention' <> 'PT0S'
      or retention_policy_property ->> 'yearlyRetention' <> 'PT0S')
      and name <> 'master';
  EOQ
}

# Assessment Queries

query "azure_sql_database_tde_status" {
  sql = <<-EOQ
    select
      tde_status,
      count(*)
    from (
      select
        case when  transparent_data_encryption ->> 'status' <> 'Enabled' then 'disabled'
        else 'enabled'
        end tde_status
      from
        azure_sql_database
      where
        name <> 'master') as s
    group by
      tde_status
    order by
      tde_status;
  EOQ
}

query "azure_sql_database_vulnerability_assessment_status" {
  sql = <<-EOQ
    with vulnerability_assessment_enabled as (
      select
        distinct id
      from
        azure_sql_database as s,
        jsonb_array_elements(vulnerability_assessments) as va
      where
        va -> 'properties' -> 'recurringScans' ->> 'isEnabled' = 'true'
        and s.name <> 'master'
    ),
    vulnerability_assessment_status as (
      select
        case
          when s.name is not null then 'enabled'
          else 'disabled' end as vulnerability_assessment_status
      from
        azure_sql_database as s
        left join vulnerability_assessment_enabled as va on s.id = va.id
      where
        s.name <> 'master'
    )
    select
      vulnerability_assessment_status,
      count(*)
    from
      vulnerability_assessment_status
    group by
      vulnerability_assessment_status;
  EOQ
}

query "azure_sql_database_geo_redundant_backup_status" {
  sql = <<-EOQ
    select
      geo_redundant_backup_status,
      count(*)
    from (
      select
        case
          when
            retention_policy_property ->> 'monthlyRetention' <> 'PT0S'
            or retention_policy_property ->> 'weeklyRetention' <> 'PT0S'
            or retention_policy_property ->> 'yearlyRetention' <> 'PT0S' then 'enabled'
          else 'disabled'
        end geo_redundant_backup_status
      from
        azure_sql_database
      where
        name <> 'master') as s
    group by
      geo_redundant_backup_status
    order by
      geo_redundant_backup_status;
  EOQ
}

# Analysis Queries

query "azure_sql_database_by_subscription" {
  sql = <<-EOQ
    select
      s.title as "Subscription",
      count(d.*) as "Databases"
    from
      azure_sql_database as d,
      azure_subscription as s
    where
      s.subscription_id = d.subscription_id
      and d.name <> 'master'
    group by
      s.title
    order by
      s.title;
  EOQ
}

query "azure_sql_database_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(resource_group) as "Accounts"
    from
      azure_sql_database as d,
      azure_subscription as sub
    where
       d.subscription_id = sub.subscription_id
       and d.name <> 'master'
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_sql_database_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Databases"
    from
      azure_sql_database
    where
      name <> 'master'
    group by
      region
    order by
      region;
  EOQ
}

query "azure_sql_database_by_creation_month" {
  sql = <<-EOQ
    with databases as (
      select
        title,
        creation_date,
        to_char(creation_date,
          'YYYY-MM') as creation_month
      from
        azure_sql_database
      where name <> 'master'
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
          (
            select
              min(creation_date)
              from databases)),
          date_trunc('month',
            current_date),
          interval '1 month') as d
        ),
    databases_by_month as (
      select
        creation_month,
        count(*)
      from
        databases
      group by
        creation_month
    )
    select
      months.month,
      databases_by_month.count
    from
      months
      left join databases_by_month on months.month = databases_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "azure_sql_database_by_status" {
  sql = <<-EOQ
    select
      status as "Status",
      count(status) as "Databases"
    from
      azure_sql_database
    where
      name <> 'master'
    group by
      status
    order by
      status;
  EOQ
}

query "azure_sql_database_by_edition" {
  sql = <<-EOQ
    select
      edition as "Edition",
      count(edition) as "Databases"
    from
      azure_sql_database
    where
      name <> 'master'
    group by
      edition
    order by
      edition;
  EOQ
}

