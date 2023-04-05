dashboard "cosmosdb_account_dashboard" {

  title         = "Azure CosmosDB Account Dashboard"
  documentation = file("./dashboards/cosmosdb/docs/cosmosdb_account_dashboard.md")

  tags = merge(local.cosmosdb_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.cosmosdb_account_count
      width = 2
    }

    card {
      query = query.cosmosdb_account_public_count
      width = 2
    }

    card {
      query = query.cosmosdb_account_automatic_failover_disabled_count
      width = 2
    }

    card {
      query = query.cosmosdb_account_private_link_disabled_count
      width = 2
    }
  }

  container {

    title = "Assessments"

    chart {
      title = "Public/Private Status"
      query = query.cosmosdb_account_public_status
      type  = "donut"
      width = 3

      series "accounts" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Automatic Failover Status"
      query = query.cosmosdb_account_automatic_failover_status
      type  = "donut"
      width = 3

      series "accounts" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Private Link Status"
      query = query.cosmosdb_account_private_link_status
      type  = "donut"
      width = 3

      series "accounts" {
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
      title = "Accounts by Subscription"
      query = query.cosmosdb_account_by_subscription
      type  = "column"
      width = 4
    }

    chart {
      title = "Accounts by Resource Group"
      query = query.cosmosdb_account_by_resource_group
      type  = "column"
      width = 4
    }

    chart {
      title = "Accounts by Region"
      query = query.cosmosdb_account_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Accounts by Kind"
      query = query.cosmosdb_account_by_kind
      type  = "column"
      width = 4
    }

    chart {
      title = "Accounts by Encryption Type"
      query = query.cosmosdb_account_by_encryption_type
      type  = "column"
      width = 4
    }
  }

}

# Card Queries

query "cosmosdb_account_count" {
  sql = <<-EOQ
    select count(*) as "Accounts" from azure_cosmosdb_account;
  EOQ
}

query "cosmosdb_account_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_cosmosdb_account
    where
      public_network_access = 'Enabled';
  EOQ
}

query "cosmosdb_account_automatic_failover_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Automatic Failover Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_cosmosdb_account
    where
      not enable_automatic_failover;
  EOQ
}

query "cosmosdb_account_private_link_disabled_count" {
  sql = <<-EOQ
    with private_link_enabled as (
      select
        distinct s.id
      from
        azure_cosmosdb_account as s,
        jsonb_array_elements(private_endpoint_connections) as connection
      where
        connection ->> 'PrivateLinkServiceConnectionStateStatus' = 'Approved'
    ),
    private_link_status as (
      select
        case
          when va.id is not null then 'enabled'
          else 'disabled' end as private_link
      from
        azure_cosmosdb_account as s
        left join private_link_enabled as va on s.id = va.id
    )
    select
      count(*) as value,
      'Private Link Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      private_link_status
    where
      private_link = 'disabled';
  EOQ
}

# Assessment Queries

query "cosmosdb_account_public_status" {
  sql = <<-EOQ
    select
      public_network,
      count(*) as accounts
    from (
      select
        case when public_network_access = 'Enabled' then 'public'
        else 'private'
        end public_network
      from
        azure_cosmosdb_account) as s
    group by
      public_network
    order by
      public_network;
  EOQ
}

query "cosmosdb_account_automatic_failover_status" {
  sql = <<-EOQ
    select
      automatic_failover,
      count(*) as accounts
    from (
      select
        case when not enable_automatic_failover then 'disabled'
        else 'enabled'
        end automatic_failover
      from
        azure_cosmosdb_account) as s
    group by
      automatic_failover
    order by
      automatic_failover;
  EOQ
}

query "cosmosdb_account_private_link_status" {
  sql = <<-EOQ
    with private_link_enabled as (
      select
        distinct s.id
      from
        azure_cosmosdb_account as s,
        jsonb_array_elements(private_endpoint_connections) as connection
      where
        connection ->> 'PrivateLinkServiceConnectionStateStatus' = 'Approved'
    ),
    private_link_status as (
      select
        case
          when va.id is not null then 'enabled'
          else 'disabled' end as private_link_enabled
      from
        azure_cosmosdb_account as s
        left join private_link_enabled as va on s.id = va.id
    )
    select
      private_link_enabled,
      count(*) as accounts
    from
      private_link_status
    group by
      private_link_enabled;
  EOQ
}

# Analysis Queries

query "cosmosdb_account_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(s.*) as "Accounts"
    from
      azure_cosmosdb_account as s,
      azure_subscription as sub
    where
      sub.subscription_id = s.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "cosmosdb_account_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(s.*) as "Accounts"
    from
      azure_cosmosdb_account as s,
      azure_subscription as sub
    where
       s.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "cosmosdb_account_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Accounts"
    from
      azure_cosmosdb_account
    group by
      region
    order by
      region;
  EOQ
}

query "cosmosdb_account_by_kind" {
  sql = <<-EOQ
    select
      kind as "Kind",
      count(kind) as "Accounts"
    from
      azure_cosmosdb_account
    group by
      kind
    order by
      kind;
  EOQ
}

query "cosmosdb_account_by_encryption_type" {
  sql = <<-EOQ
    select
      encryption as "Encryption",
      count(*) as "Accounts"
    from (
      select
        case when key_vault_key_uri is null then 'Platform-Managed'
        else 'Customer-Managed'
        end encryption
      from
        azure_cosmosdb_account) as s
    group by
      "Encryption"
    order by
      "Encryption";
  EOQ
}