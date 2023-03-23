dashboard "cosmosdb_account_detail" {
  title         = "Azure CosmosDB Account Detail"
  documentation = file("./dashboards/cosmosdb/docs/cosmosdb_account_detail.md")

  tags = merge(local.cosmosdb_common_tags, {
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
      query = query.cosmosdb_account_database_count
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

    card {
      width = 2
      query = query.cosmosdb_account_automatic_failover
      args  = [self.input.cosmosdb_account_id.value]
    }

    card {
      width = 2
      query = query.cosmosdb_account_analytical_storage
      args  = [self.input.cosmosdb_account_id.value]
    }
  }

  with "key_vault_keys_for_cosmosdb_account" {
    query = query.key_vault_keys_for_cosmosdb_account
    args  = [self.input.cosmosdb_account_id.value]
  }

  with "key_vault_vaults_for_cosmosdb_account" {
    query = query.key_vault_vaults_for_cosmosdb_account
    args  = [self.input.cosmosdb_account_id.value]
  }

  with "network_subnets_for_cosmosdb_account" {
    query = query.network_subnets_for_cosmosdb_account
    args  = [self.input.cosmosdb_account_id.value]
  }

  with "network_virtual_networks_for_cosmosdb_account" {
    query = query.network_virtual_networks_for_cosmosdb_account
    args  = [self.input.cosmosdb_account_id.value]
  }

  with "cosmosdb_mongo_database_for_cosmosdb_account" {
    query = query.cosmosdb_mongo_database_for_cosmosdb_account
    args  = [self.input.cosmosdb_account_id.value]
  }

  with "cosmosdb_sql_database_for_cosmosdb_account" {
    query = query.cosmosdb_sql_database_for_cosmosdb_account
    args  = [self.input.cosmosdb_account_id.value]
  }

  container {
    graph {
      title = "Relationships"
      type  = "graph"

      node {
        base = node.key_vault_key
        args = {
          key_vault_key_ids = with.key_vault_keys_for_cosmosdb_account.rows[*].key_vault_key_id
        }
      }

      node {
        base = node.key_vault_vault
        args = {
          key_vault_vault_ids = with.key_vault_vaults_for_cosmosdb_account.rows[*].key_vault_id
        }
      }

      node {
        base = node.network_subnet
        args = {
          network_subnet_ids = with.network_subnets_for_cosmosdb_account.rows[*].subnet_id
        }
      }

      node {
        base = node.network_virtual_network
        args = {
          network_virtual_network_ids = with.network_virtual_networks_for_cosmosdb_account.rows[*].virtual_network_id
        }
      }

      node {
        base = node.cosmosdb_mongo_database
        args = {
          cosmosdb_mongo_database_ids = with.cosmosdb_mongo_database_for_cosmosdb_account.rows[*].mongo_database_id
        }
      }

      node {
        base = node.cosmosdb_sql_database
        args = {
          cosmosdb_sql_database_ids = with.cosmosdb_sql_database_for_cosmosdb_account.rows[*].sql_database_id
        }
      }

      node {
        base = node.cosmosdb_account
        args = {
          cosmosdb_account_ids = [self.input.cosmosdb_account_id.value]
        }
      }


      edge {
        base = edge.network_subnet_to_network_virtual_network
        args = {
          network_subnet_ids = with.network_subnets_for_cosmosdb_account.rows[*].subnet_id
        }
      }

      edge {
        base = edge.cosmosdb_account_to_key_vault
        args = {
          cosmosdb_account_ids = [self.input.cosmosdb_account_id.value]
        }
      }

      edge {
        base = edge.cosmosdb_account_to_key_vault_key
        args = {
          cosmosdb_account_ids = [self.input.cosmosdb_account_id.value]
        }
      }

      edge {
        base = edge.cosmosdb_account_to_network_subnet
        args = {
          cosmosdb_account_ids = [self.input.cosmosdb_account_id.value]
        }
      }

      edge {
        base = edge.cosmosdb_account_to_cosmosdb_mongo_database
        args = {
          cosmosdb_account_ids = [self.input.cosmosdb_account_id.value]
        }
      }

      edge {
        base = edge.cosmosdb_account_to_cosmosdb_sql_database
        args = {
          cosmosdb_account_ids = [self.input.cosmosdb_account_id.value]
        }
      }
    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 3
        query = query.cosmosdb_account_overview
        args  = [self.input.cosmosdb_account_id.value]
      }

      table {
        title = "Tags"
        width = 3
        query = query.cosmosdb_account_tags
        args  = [self.input.cosmosdb_account_id.value]
      }

      table {
        title = "Failover Policy"
        width = 3
        query = query.cosmosdb_account_failover_policy
        args  = [self.input.cosmosdb_account_id.value]
      }

      table {
        title = "Firewall Policy"
        width = 3
        query = query.cosmosdb_account_firewall_policies
        args  = [self.input.cosmosdb_account_id.value]
      }
    }

    container {

      width = 12

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
        title = "Virtual Network Rules"
        width = 12
        query = query.cosmosdb_account_virtual_network_rules
        args  = [self.input.cosmosdb_account_id.value]
      }

      table {
        title = "Private Endpoint Connection"
        width = 12
        query = query.cosmosdb_account_private_endpoint_connection
        args  = [self.input.cosmosdb_account_id.value]
      }

      table {
        title = "Database Details"
        width = 12
        query = query.cosmosdb_account_database_details
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

query "cosmosdb_account_database_count" {
  sql = <<-EOQ
    select
      'Database Count' as label,
      count(*) as value
    from
      azure_cosmosdb_account a,
      azure_cosmosdb_mongo_database d
    where
      a.name = d.account_name
      and lower(a.id) = $1;
  EOQ
}

query "cosmosdb_account_analytical_storage" {
  sql = <<-EOQ
    select
      'Storage Analytics' as label,
      case when enable_analytical_storage then 'Enabled' else 'Disabled' end as value,
      case when enable_analytical_storage then 'ok' else 'alert' end as type
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

query "key_vault_keys_for_cosmosdb_account" {
  sql = <<-EOQ
    select
      lower(k.id) as key_vault_key_id
    from
      azure_cosmosdb_account a,
      azure_key_vault_key k
    where
      a.key_vault_key_uri = k.key_uri
      and lower(a.id) = $1;
  EOQ
}

query "key_vault_vaults_for_cosmosdb_account" {
  sql = <<-EOQ
    select
      lower(split_part(k.id, '/keys/', 1)) as key_vault_id
    from
      azure_cosmosdb_account a,
      azure_key_vault_key k
    where
      a.key_vault_key_uri = k.key_uri
      and lower(a.id) = $1;
  EOQ
}

query "network_subnets_for_cosmosdb_account" {
  sql = <<-EOQ
    select
      lower(r ->> 'id') as subnet_id
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(id) = $1;
  EOQ
}

query "network_virtual_networks_for_cosmosdb_account" {
  sql = <<-EOQ
    select
      distinct lower(split_part(r ->> 'id', '/subnets', 1)) as virtual_network_id
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_mongo_database_for_cosmosdb_account" {
  sql = <<-EOQ
    select
      lower(d.id) as mongo_database_id
    from
      azure_cosmosdb_account a,
      azure_cosmosdb_mongo_database d
    where
      d.account_name = a.name
      and lower(a.id) = $1;
  EOQ
}

query "cosmosdb_sql_database_for_cosmosdb_account" {
  sql = <<-EOQ
    select
      lower(d.id) as sql_database_id
    from
      azure_cosmosdb_account a,
      azure_cosmosdb_sql_database d
    where
      d.account_name = a.name
      and lower(a.id) = $1;
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

query "cosmosdb_account_private_endpoint_connection" {
  sql = <<-EOQ
    select
      c ->> 'PrivateEndpointConnectionName' as "Private Endpoint Connection Name",
      c ->> 'PrivateEndpointConnectionType' as "Private Endpoint Connection Type",
      c ->> 'PrivateEndpointId' as "Private Endpoint ID",
      c ->> 'PrivateLinkServiceConnectionStateActionsRequired' as "Private Link Service Connection State Actions Required",
      c ->> 'PrivateLinkServiceConnectionStateDescription' as "Private Link Service Connection State Description",
      c ->> 'PrivateLinkServiceConnectionStateStatus' as "Private Link Service Connection State Status",
      c ->> 'ProvisioningState' as "Provisioning State",
      c ->> 'PrivateEndpointConnectionId' as "Private Endpoint Connection ID"
    from
      azure_cosmosdb_account,
      jsonb_array_elements(private_endpoint_connections_t) as c
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_firewall_policies" {
  sql = <<-EOQ
    select
      ip ->> 'ipAddressOrRange' "IP Address/Range",
      'Allow' as "Action"
    from
      azure_cosmosdb_account,
      jsonb_array_elements(ip_rules) as ip
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_account_database_details" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.account_name as "Account Name",
      d.throughput_settings ->> 'Throughput' as "Throughput",
      a.kind as "Database Server",
      d.id as "ID"
    from
      azure_cosmosdb_mongo_database as d
      join azure_cosmosdb_account as a on d.account_name = a.name
    where
      lower(a.id) = $1;
  EOQ
}