dashboard "cosmosdb_account_detail" {
  title         = "CosmosDB Account Detail"
  documentation = file("./dashboards/documentdb/docs/cosmosdb_account_detail.md")

  tags = merge(local.documentdb_cosmosdb_common_tags, {
    type = "Detail"
  })

  input "cosmosdb_account_id" {
    title = "Select an account:"
    query = query.cosmosdb_account_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.cosmosdb_account_server
      args  = [self.input.cosmosdb_account_id.value]
    }

    card {
      width = 2
      query = query.cosmosdb_account_free_tier
      args  = [self.input.cosmosdb_account_id.value]
    }

    card {
      width = 2
      query = query.cosmosdb_account_automatic_failover
      args  = [self.input.cosmosdb_account_id.value]
    }

    card {
      width = 2
      query = query.cosmosdb_account_public_access
      args  = [self.input.cosmosdb_account_id.value]
    }

    card {
      width = 2
      query = query.cosmosdb_account_encryption
      args  = [self.input.cosmosdb_account_id.value]
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.cosmosdb_account_overview
        args  = [self.input.cosmosdb_account_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.cosmosdb_account_tags
        args  = [self.input.cosmosdb_account_id.value]
      }
    }

    container {
      width = 12

      table {
        title = "Virtual Network Rules"
        width = 6
        query = query.cosmosdb_account_virtual_network_rules
        args  = [self.input.cosmosdb_account_id.value]
      }

      table {
        title = "Encryption Details"
        width = 6
        query = query.cosmosdb_account_encryption_details
        args  = [self.input.cosmosdb_account_id.value]
      }
      table {
        title = "Backup Policy"
        width = 6
        query = query.cosmosdb_account_backup_policy
        args  = [self.input.cosmosdb_account_id.value]
      }
      table {
        title = "Failover Policy"
        width = 6
        query = query.cosmosdb_account_failover_policy
        args  = [self.input.cosmosdb_account_id.value]
      }
    }
  }

}

query "cosmosdb_account_input" {
  sql = <<-EOQ
    select
      a.title as label,
      lower(a.id) as value,
      json_build_object(
        'subscription', sub.display_name,
        'resource_group', a.resource_group,
        'region', a.region
      ) as tags
    from
      azure_cosmosdb_account as a,
      azure_subscription as sub
    where
      lower(a.subscription_id) = lower(sub.subscription_id)
    order by
      a.title;
  EOQ
}

query "cosmosdb_account_server" {
  sql = <<-EOQ
    select
      'Server Name' as label,
      kind as value
    from
      azure_cosmosdb_account
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_free_tier" {
  sql = <<-EOQ
    select
      'Free Tier' as label,
      case when enable_free_tier then 'Enabled' else 'Disabled' end as value,
      case when enable_free_tier then 'ok' else 'alert' end as type
    from
      azure_cosmosdb_account
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_automatic_failover" {
  sql = <<-EOQ
    select
      'Automatic Failover' as label,
      case when enable_automatic_failover then 'Enabled' else 'Disabled' end as value,
      case when enable_automatic_failover then 'ok' else 'alert' end as type
    from
      azure_cosmosdb_account
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_public_access" {
  sql = <<-EOQ
    select
      'Publicly Accessible' as label,
      case when public_network_access = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when public_network_access = 'Enabled' then 'ok' else 'alert' end as type
    from
      azure_cosmosdb_account
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when key_vault_key_uri is not null then 'Enabled' else 'Disabled' end as value,
      case when key_vault_key_uri is not null then 'ok' else 'alert' end as type
    from
      azure_cosmosdb_account
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      server_version as "Server Version",
      database_account_offer_type as "Offer Type",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_cosmosdb_account
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_cosmosdb_account,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
  EOQ
}

query "cosmosdb_account_virtual_network_rules" {
  sql = <<-EOQ
    select
      split_part(r ->> 'id', '/', 9) as "Name",
      split_part(r ->> 'id', '/subnets', 1) as "ID",
      r ->> 'id' as "Virtual Network Subnet ID",
      r ->> 'ignoreMissingVnetServiceEndpoint' as "Ignore Missing VNet Service Endpoint"
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_encryption_details" {
  sql = <<-EOQ
    select
      k.name as "Name",
      vault_name as "Vault Name",
      key_type as "Key Type",
      key_size as "Key Size",
      key_uri_with_version as "Key URI"
    from
      azure_cosmosdb_account a,
      azure_key_vault_key k
    where
      a.key_vault_key_uri = k.key_uri
      and lower(a.id) = $1;
  EOQ
}

query "cosmosdb_account_backup_policy" {
  sql = <<-EOQ
    select
      backup_policy ->> 'type' as "Type",
      backup_policy -> 'periodicModeProperties' ->> 'backupIntervalInMinutes' as "Backup Interval - (minutes)",
      backup_policy -> 'periodicModeProperties' ->> 'backupRetentionIntervalInHours' as "Backup Retention Interval - (hours)",
      backup_policy -> 'periodicModeProperties' ->> 'backupStorageRedundancy' as "Backup Storage Redundancy"
    from
      azure_cosmosdb_account
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_failover_policy" {
  sql = <<-EOQ
    select
      f ->> 'failoverPriority' as "Failover Priority",
      f ->> 'locationName' as "Location"
    from
      azure_cosmosdb_account,
      jsonb_array_elements(failover_policies) f
    where
      lower(id) = $1;
  EOQ
}