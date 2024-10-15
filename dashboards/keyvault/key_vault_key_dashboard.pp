dashboard "key_vault_key_dashboard" {

  title         = "Azure Key Vault Key Dashboard"
  documentation = file("./dashboards/keyvault/docs/key_vault_key_dashboard.md")

  tags = merge(local.keyvault_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.key_vault_key_count
      width = 3
    }

    card {
      query = query.key_vault_key_enabled_count
      width = 3
    }

    card {
      query = query.key_vault_key_expiration_set_count
      width = 3
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Enabled/Disabled Status"
      query = query.key_vault_key_by_enabled_status
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
      title = "Expiration Status"
      query = query.key_vault_key_by_key_expiration_status
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
      title = "Keys by Subscription"
      query = query.key_vault_key_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Resource Group"
      query = query.key_vault_key_by_resource_group
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Region"
      query = query.key_vault_key_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Age"
      query = query.key_vault_key_by_creation_month
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Type"
      query = query.key_vault_key_by_type
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Recovery level"
      query = query.key_vault_key_by_recovery_level
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Size"
      query = query.key_vault_key_by_size
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "key_vault_key_count" {
  sql = <<-EOQ
    select count(*) as "Keys" from azure_key_vault_key;
  EOQ
}

query "key_vault_key_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Enabled' as label,
      case when count(*) > 0 then 'ok' else 'alert' end as "type"
    from
      azure_key_vault_key
    where
      enabled;
  EOQ
}

query "key_vault_key_expiration_set_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      'Expiration Set Disabled' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      azure_key_vault_key
    where
      expires_at is null;
  EOQ
}

# Assessment Queries

query "key_vault_key_by_enabled_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select enabled,
        case when enabled then 'enabled'
        else 'disabled'
        end status
      from
        azure_key_vault_key) as kv
    group by
      status
    order by
      status;
  EOQ
}

query "key_vault_key_by_key_expiration_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select expires_at,
        case when expires_at is not null then 'enabled'
        else 'disabled'
        end status
      from
        azure_key_vault_key) as kv
    group by
      status
    order by
      status;
  EOQ
}

# Analysis Queries

query "key_vault_key_by_subscription" {
  sql = <<-EOQ
    select
      a.title as "Subscription",
      count(v.*) as "Keys"
    from
      azure_key_vault_key as v,
      azure_subscription as a
    where
      a.subscription_id = v.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "key_vault_key_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(k.*) as "Keys"
    from
      azure_key_vault_key as k,
      azure_subscription as sub
    where
      k.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "key_vault_key_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Keys" from azure_key_vault_key group by region order by region;
  EOQ
}

query "key_vault_key_by_creation_month" {
  sql = <<-EOQ
    with keys as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        azure_key_vault_key
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_at)
                from keys)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    keys_by_month as (
      select
        creation_month,
        count(*)
      from
        keys
      group by
        creation_month
    )
    select
      months.month,
      keys_by_month.count
    from
      months
      left join keys_by_month on months.month = keys_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "key_vault_key_by_type" {
  sql = <<-EOQ
    select
      key_type as "Type",
      count(key_type) as "Keys"
    from
      azure_key_vault_key
    group by
      key_type
    order by
      key_type;
  EOQ
}

query "key_vault_key_by_recovery_level" {
  sql = <<-EOQ
    select
      recovery_level as "Recovery Level",
      count(recovery_level) as "Keys"
    from
      azure_key_vault_key
    group by
      recovery_level
    order by
      recovery_level;
  EOQ
}

query "key_vault_key_by_size" {
  sql = <<-EOQ
    select
      key_size as "Size",
      count(key_size) as "Keys"
    from
      azure_key_vault_key
    group by
      key_size
    order by
      key_size;
  EOQ
}
