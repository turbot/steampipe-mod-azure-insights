dashboard "key_vault_key_detail" {

  title         = "Azure Key Vault Key Detail"
  documentation = file("./dashboards/keyvault/docs/key_vault_key_detail.md")

  tags = merge(local.keyvault_common_tags, {
    type = "Detail"
  })

  input "key_vault_key_id" {
    title = "Select a key:"
    query = query.key_vault_key_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.key_vault_key_type
      args = {
        id = self.input.key_vault_key_id.value
      }
    }

    card {
      width = 2
      query = query.key_vault_key_size
      args = {
        id = self.input.key_vault_key_id.value
      }
    }

    card {
      width = 2
      query = query.key_vault_key_status
      args = {
        id = self.input.key_vault_key_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "compute_disk_encryption_sets" {
        sql = <<-EOQ
          select
            lower(s.id) as disk_encryption_set_id
          from
            azure_key_vault_key_version as v
            left join azure_compute_disk_encryption_set as s on s.active_key_url = v.key_uri_with_version
          where
            s.id is not null
            and lower(split_part(v.id, '/versions', 1)) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      with "container_registries" {
        sql = <<-EOQ
          select
            lower(r.id) as registry_id
          from
            azure_key_vault_key as k
            left join azure_container_registry as r on r.encryption -> 'keyVaultProperties' ->> 'keyIdentifier' = k.key_uri
            left join azure_key_vault_key_version as v on v.key_uri_with_version = k.key_uri_with_version
          where
            r.id is not null
            and lower(k.id) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      with "eventhub_namespaces" {
        sql = <<-EOQ
          select
            lower(n.id) as eventhub_namespace_id
          from
            azure_eventhub_namespace as n,
            jsonb_array_elements(encryption -> 'keyVaultProperties') as p
            left join azure_key_vault_key as k on p ->> 'keyName' = k.name
            left join azure_key_vault as v on v.name = k.vault_name
          where
            k.resource_group = v.resource_group
            and k.resource_group = n.resource_group
            and lower(k.id) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      with "key_vault_vaults" {
        sql = <<-EOQ
          select
            lower(v.id) as vault_id
          from
            azure_key_vault_key as k
            left join azure_key_vault as v on v.name = k.vault_name
          where
            lower(k.id) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      with "postgresql_servers" {
        sql = <<-EOQ
          select
            lower(s.id) as postgresql_server_id
          from
            azure_postgresql_server as s,
            jsonb_array_elements(server_keys) as sk
            left join azure_key_vault_key_version as v on lower(sk ->> 'ServerKeyUri') = lower(v.key_uri_with_version)
          where
            lower(split_part(v.id, '/versions', 1)) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      with "servicebus_namespaces" {
        sql = <<-EOQ
          select
            lower(n.id) as servicebus_namespace_id
          from
            azure_servicebus_namespace as n,
            jsonb_array_elements(encryption -> 'keyVaultProperties') as p
            left join azure_key_vault_key as k on p ->> 'keyName' = k.name
            left join azure_key_vault as v on v.name = k.vault_name
          where
            n.id is not null
            and lower(k.resource_group) = lower(v.resource_group)
            and lower(k.resource_group) = lower(n.resource_group)
            and lower(k.id) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      with "sql_servers" {
        sql = <<-EOQ
          with sql_server as (
            select
              ep ->> 'uri' as uri,
              id,
              title,
              name,
              type,
              region,
              resource_group,
              subscription_id
            from
              azure_sql_server,
              jsonb_array_elements(encryption_protector) as ep
            where
              ep ->> 'kind' = 'azurekeyvault'
          )
          select
            lower(s.id) as sql_server_id
          from
            azure_key_vault_key_version as v
            left join sql_server as s on v.key_uri_with_version = s.uri
          where
            s.uri is not null
            and lower(split_part(v.id, '/versions', 1)) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      with "storage_storage_accounts" {
        sql = <<-EOQ
          select
            lower(s.id) as account_id
          from
            azure_storage_account as s
            left join azure_key_vault_key_version as v on lower(s.encryption_key_vault_properties_key_current_version_id) = lower(v.key_uri_with_version)
          where
            lower(split_part(v.id, '/versions', 1)) = $1;
        EOQ

        args = [self.input.key_vault_key_id.value]
      }

      nodes = [
        node.compute_disk_encryption_set,
        node.container_registry,
        node.eventhub_namespace,
        node.key_vault_key,
        node.key_vault_key_version,
        node.key_vault_vault,
        node.postgresql_server,
        node.servicebus_namespace,
        node.sql_server,
        node.storage_storage_account
      ]

      edges = [
        edge.compute_disk_encryption_set_to_key_vault_key_version,
        edge.container_registry_to_key_vault_key_version,
        edge.eventhub_namespace_to_key_vault_key_version,
        edge.key_vault_key_to_key_vault,
        edge.key_vault_key_version_to_key_vault_key,
        edge.postgresql_server_to_key_vault_key_version,
        edge.servicebus_namespace_to_key_vault_key,
        edge.sql_server_to_key_vault_key_version,
        edge.storage_account_to_key_vault_key_version
      ]

      args = {
        compute_disk_encryption_set_ids = with.compute_disk_encryption_sets.rows[*].disk_encryption_set_id
        container_registry_ids          = with.container_registries.rows[*].registry_id
        eventhub_namespace_ids          = with.eventhub_namespaces.rows[*].eventhub_namespace_id
        key_vault_key_ids               = [self.input.key_vault_key_id.value]
        key_vault_vault_ids             = with.key_vault_vaults.rows[*].vault_id
        postgresql_server_ids           = with.postgresql_servers.rows[*].postgresql_server_id
        servicebus_namespace_ids        = with.servicebus_namespaces.rows[*].servicebus_namespace_id
        sql_server_ids                  = with.sql_servers.rows[*].sql_server_id
        storage_account_ids             = with.storage_storage_accounts.rows[*].account_id
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.key_vault_key_overview
        args = {
          id = self.input.key_vault_key_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.key_vault_key_tags
        args = {
          id = self.input.key_vault_key_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Key Age"
        query = query.key_vault_key_age
        args = {
          id = self.input.key_vault_key_id.value
        }
      }

    }

  }

}

query "key_vault_key_input" {
  sql = <<-EOQ
    select
      v.title as label,
      lower(k.id) as value,
      json_build_object(
        'Key Name', k.name,
        'Vault Name', v.vault_name,
        'Subscription', s.display_name,
        'Resource_group', v.resource_group,
        'region', v.region
      ) as tags
    from
      azure_key_vault_key as k
      left join azure_key_vault_key_version as v on k.key_uri = v.key_uri,
      azure_subscription as s
    where
      v.subscription_id = s.subscription_id
    order by
      v.title;
  EOQ
}

query "key_vault_key_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      case when enabled then 'Enabled' else 'Disabled' end as value,
      case when enabled then 'ok' else 'alert' end as type
    from
      azure_key_vault_key
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "key_vault_key_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      key_type as value
    from
      azure_key_vault_key
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "key_vault_key_size" {
  sql = <<-EOQ
    select
      'Size (Bits)' as label,
      key_size as value
    from
      azure_key_vault_key
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "key_vault_key_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      type as "Type",
      vault_name as "Vault Name",
      key_uri as "URI",
      key_uri_with_version as "URI With Version",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_key_vault_key
    where
      lower(id) = $1
  EOQ

  param "id" {}
}

query "key_vault_key_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_key_vault_key
    where
      lower(id) = $1
    order by
      tags ->> 'Key';
    EOQ

  param "id" {}
}

query "key_vault_key_age" {
  sql = <<-EOQ
    select
      created_at as "Created At",
      expires_at as "Expires At",
      updated_at as "Updated At"
    from
      azure_key_vault_key
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}
