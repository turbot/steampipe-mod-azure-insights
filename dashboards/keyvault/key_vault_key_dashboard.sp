dashboard "azure_key_vault_key_dashboard" {

  title = "Azure Key Vault Key Dashboard"

  tags = merge(local.kms_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.azure_key_vault_key_count.sql
      width = 2
    }

    card {
      sql   = query.azure_key_vault_key_enabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_key_vault_key_expiration_set_count.sql
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Enabled State"
      sql   = query.azure_key_vault_key_by_enabled_status.sql
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
      title = "Expiration State"
      sql   = query.azure_key_vault_key_by_key_expiration_status.sql
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
      sql   = query.azure_key_vault_key_by_subscription.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Resource Group"
      sql   = query.azure_key_vault_key_by_resource_group.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Region"
      sql   = query.azure_key_vault_key_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Type"
      sql   = query.azure_key_vault_key_by_type.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Size"
      sql   = query.azure_key_vault_key_by_size.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "azure_key_vault_key_count" {
  sql = <<-EOQ
    select count(*) as "Keys" from azure_key_vault_key;
  EOQ
}

query "azure_key_vault_key_enabled_count" {
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

query "azure_key_vault_key_expiration_set_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      'Expiration Set' as label,
      case when count(*) > 0 then 'ok' else 'alert' end as "type"
    from
      azure_key_vault_key
    where
      expires_at is not null;
  EOQ
}

# Assessment Queries

query "azure_key_vault_key_by_enabled_status" {
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

query "azure_key_vault_key_by_key_expiration_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select expires_at,
        case when expires_at is not null then 'set'
        else 'not set'
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

query "azure_key_vault_key_by_subscription" {
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

query "azure_key_vault_key_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group as "Resource Group",
      count(resource_group) as "Keys"
    from
      azure_key_vault_key
    group by
      resource_group
    order by
      resource_group;
  EOQ
}

query "azure_key_vault_key_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Keys" from azure_key_vault_key group by region order by region;
  EOQ
}

query "azure_key_vault_key_by_type" {
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

query "azure_key_vault_key_by_size" {
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
