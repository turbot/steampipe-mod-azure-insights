dashboard "azure_storage_account_dashboard" {

  title = "Azure Storage Account Dashboard"
  documentation = file("./dashboards/storage/docs/storage_account_dashboard.md")

  tags = merge(local.storage_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.azure_storage_account_count.sql
      width = 2
    }

    # Assessments

    card {
      sql   = query.azure_storage_account_blob_soft_delete_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_storage_account_blob_public_access_enabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_storage_account_https_traffic_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_storage_account_unrestricted_network_access_count.sql
      width = 2
    }

    card {
      sql   = query.azure_storage_account_infrastructure_encryption_disabled_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Blob Soft Delete Status"
      sql   = query.azure_storage_account_blob_soft_delete_status.sql
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
      title = "Blob Public Access Status"
      sql   = query.azure_storage_account_blob_public_access_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }

    chart {
      title = "HTTPS Status"
      sql   = query.azure_storage_account_https_traffic_status.sql
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
      title = "Network Access Status"
      sql   = query.azure_storage_account_network_access_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Infrastructure Encryption Status"
      sql   = query.azure_storage_account_infrastructure_encryption_status.sql
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
      title = "Storage Accounts by Subscription"
      sql   = query.azure_storage_account_by_subscription.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Storage Accounts by Resource Group"
      sql   = query.azure_storage_account_by_resource_group.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Storage Accounts by Region"
      sql   = query.azure_storage_account_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Storage Accounts by Access Tier"
      sql   = query.azure_storage_account_by_access_tier.sql
      type  = "column"
      width = 3
    }
  }

}

# Card Queries

query "azure_storage_account_count" {
  sql = <<-EOQ
    select count(*) as "Storage Accounts" from azure_storage_account;
  EOQ
}

query "azure_storage_account_blob_soft_delete_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Blob Soft Delete Disabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      blob_soft_delete_enabled is not true;
  EOQ
}

query "azure_storage_account_blob_public_access_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Blob Public Access Enabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      allow_blob_public_access;
  EOQ
}

query "azure_storage_account_https_traffic_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'HTTPS Disabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      enable_https_traffic_only is not true;
  EOQ
}

query "azure_storage_account_unrestricted_network_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unrestricted Network Access' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      network_rule_default_action <> 'Deny'
  EOQ
}

query "azure_storage_account_infrastructure_encryption_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Infrastructure Unencrypted' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      require_infrastructure_encryption is not true;
  EOQ
}

query "azure_storage_account_blob_soft_delete_status" {
  sql = <<-EOQ
    select
      blob_soft_delete,
      count(*)
    from (
      select
        case when blob_soft_delete_enabled then
          'enabled'
        else
          'disabled'
        end blob_soft_delete
      from
        azure_storage_account) as cd
    group by
      blob_soft_delete
    order by
      blob_soft_delete;
  EOQ
}

query "azure_storage_account_blob_public_access_status" {
  sql = <<-EOQ
    select
      public_access,
      count(*)
    from (
      select
        case when allow_blob_public_access then 'public'
        else 'private'
        end public_access
      from
        azure_storage_account) as cd
    group by
      public_access
    order by
      public_access;
  EOQ
}

query "azure_storage_account_https_traffic_status" {
  sql = <<-EOQ
    select
      https_traffic,
      count(*)
    from (
      select
        case when enable_https_traffic_only then 'enabled'
        else 'disabled'
        end https_traffic
      from
        azure_storage_account) as cd
    group by
      https_traffic
    order by
      https_traffic;
  EOQ
}

query "azure_storage_account_network_access_status" {
  sql = <<-EOQ
    select
      network_rule,
      count(*)
    from (
      select
        case when network_rule_default_action = 'Deny' then 'restricted'
        else 'unrestricted'
        end network_rule
      from
        azure_storage_account) as cd
    group by
      network_rule
    order by
      network_rule;
  EOQ
}

query "azure_storage_account_infrastructure_encryption_status" {
  sql = <<-EOQ
    select
      infrastructure_encryption,
      count(*)
    from (
      select
        case when require_infrastructure_encryption then 'enabled'
        else 'disabled'
        end infrastructure_encryption
      from
        azure_storage_account) as cd
    group by
      infrastructure_encryption
    order by
      infrastructure_encryption;
  EOQ
}

# Analysis Queries

query "azure_storage_account_by_subscription" {
  sql = <<-EOQ
    select
      a.title as "Subscription",
      count(v.*) as "Storage Accounts"
    from
      azure_storage_account as v,
      azure_subscription as a
    where
      a.subscription_id = v.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "azure_storage_account_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(resource_group) as "Storage Accounts"
    from
      azure_storage_account as a,
      azure_subscription as sub
    where
       a.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_storage_account_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Storage Accounts"
    from
      azure_storage_account
    group by
      region
    order by
      region;
  EOQ
}

query "azure_storage_account_by_access_tier" {
  sql = <<-EOQ
    select
      access_tier as "Access Tier",
      count(*) as "Storage Accounts"
    from
      azure_storage_account
    group by
      access_tier
    order by
      access_tier;
  EOQ
}


