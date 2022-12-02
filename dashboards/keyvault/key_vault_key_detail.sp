dashboard "azure_key_vault_key_detail" {

  title         = "Azure Key Vault Key Detail"
  documentation = file("./dashboards/keyvault/docs/key_vault_key_detail.md")

  tags = merge(local.keyvault_common_tags, {
    type = "Detail"
  })

  input "key_vault_key_id" {
    title = "Select a key:"
    query = query.azure_key_vault_key_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_key_vault_key_type
      args = {
        id = self.input.key_vault_key_id.value
      }
    }

    card {
      width = 2
      query = query.azure_key_vault_key_size
      args = {
        id = self.input.key_vault_key_id.value
      }
    }

    card {
      width = 2
      query = query.azure_key_vault_key_status
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

      nodes = [
        node.azure_key_vault_key_version_node,
        node.azure_key_vault_key_version_to_key_node,
        node.azure_key_vault_key_to_key_vault_node,
        node.azure_key_vault_key_version_from_compute_disk_encryption_set_node,
        node.azure_key_vault_key_version_from_container_registry_node,
        node.azure_key_vault_key_version_from_sql_server_node,
        node.azure_key_vault_key_from_eventhub_namespace_node,
        node.azure_key_vault_key_version_from_storage_account_node,
        node.azure_key_vault_key_from_servicebus_namespace_node,
        node.azure_key_vault_key_version_from_postgresql_server_node
      ]

      edges = [
        edge.azure_key_vault_key_version_to_key_edge,
        edge.azure_key_vault_key_to_key_vault_edge,
        edge.azure_key_vault_key_version_from_compute_disk_encryption_set_edge,
        edge.azure_key_vault_key_version_from_container_registry_edge,
        edge.azure_key_vault_key_version_from_sql_server_edge,
        edge.azure_key_vault_key_from_eventhub_namespace_edge,
        edge.azure_key_vault_key_version_from_storage_account_edge,
        edge.azure_key_vault_key_from_servicebus_namespace_edge,
        edge.azure_key_vault_key_version_from_postgresql_server_edge
      ]

      args = {
        id = self.input.key_vault_key_id.value
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
        query = query.azure_key_vault_key_overview
        args = {
          id = self.input.key_vault_key_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_key_vault_key_tags
        args = {
          id = self.input.key_vault_key_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Key Age"
        query = query.azure_key_vault_key_age
        args = {
          id = self.input.key_vault_key_id.value
        }
      }

    }

  }

}

query "azure_key_vault_key_input" {
  sql = <<-EOQ
    select
      v.title as label,
      k.id as value,
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

query "azure_key_vault_key_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      case when enabled then 'Enabled' else 'Disabled' end as value,
      case when enabled then 'ok' else 'alert' end as type
    from
      azure_key_vault_key
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_key_vault_key_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      key_type as value
    from
      azure_key_vault_key
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_key_vault_key_size" {
  sql = <<-EOQ
    select
      'Size (Bits)' as label,
      key_size as value
    from
      azure_key_vault_key
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_key_vault_key_overview" {
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
      id = $1
  EOQ

  param "id" {}
}

query "azure_key_vault_key_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_key_vault_key
    where
      id = $1
    order by
      tags ->> 'Key';
    EOQ

  param "id" {}
}

query "azure_key_vault_key_age" {
  sql = <<-EOQ
    select
      created_at as "Created At",
      expires_at as "Expires At",
      updated_at as "Updated At"
    from
      azure_key_vault_key
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_version_node" {
  category = category.azure_key_vault_key_verison

  sql = <<-EOQ
    select
      k.key_uri,
      v.id as id,
      case when k.key_uri_with_version = v.key_uri_with_version then 'current' || ' ['|| left(v.title,8) || ']' else 'older' || ' ['|| left(v.title,8) || ']' end as title,
      jsonb_build_object(
        'Version Name', v.name,
        'Key Name', v.key_name,
        'Key URI', v.key_uri,
        'ID', v.id,
        'Vault Name', v.vault_name
      ) as properties
    from
      azure_key_vault_key_version as v
      left join azure_key_vault_key as k on v.key_uri = k.key_uri
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

node "key_vault_key" {
  category = category.key_vault_key

  sql = <<-EOQ
    select
      lower(id) as id,
      name as title,
      jsonb_build_object(
        'Key Name', name,
        'Key ID', id,
        'Vault Name', vault_name
      ) as properties
    from
      azure_key_vault_key
    where
      lower(id) = any($1);
  EOQ

  param "key_vault_key_id" {}
}

node "azure_key_vault_key_version_to_key_node" {
  category = category.key_vault_key

  sql = <<-EOQ
    select
      id as id,
      name as title,
      jsonb_build_object(
        'Key Name', name,
        'Key ID', id,
        'Vault Name', vault_name
      ) as properties
    from
      azure_key_vault_key
    where
      id = $1;
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_version_to_key_edge" {
  title = "key"

  sql = <<-EOQ
    select
      v.id as from_id,
      k.id as to_id
    from
      azure_key_vault_key_version as v
      left join azure_key_vault_key as k on k.key_uri = v.key_uri
    where
      k.id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_to_key_vault_node" {
  category = category.key_vault

  sql = <<-EOQ
    select
      v.id as id,
      v.name as title,
      jsonb_build_object(
        'Name', v.name,
        'ID', v.id,
        'Type', v.type,
        'Purge Protection Enabled', v.purge_protection_enabled
      ) as properties
    from
      azure_key_vault_key as k
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.id = $1;
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_to_key_vault_edge" {
  title = "key vault"

  sql = <<-EOQ
    select
      k.id as from_id,
      v.id as to_id
    from
      azure_key_vault_key as k
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_version_from_compute_disk_encryption_set_node" {
  category = category.azure_compute_disk_encryption_set

  sql = <<-EOQ
    select
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Provisioning State', s.provisioning_state,
        'Encryption Type', s.encryption_type,
        'Type', s.type,
        'Region', s.region,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_key_vault_key_version as v
      left join azure_compute_disk_encryption_set as s on s.active_key_url = v.key_uri_with_version
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_version_from_compute_disk_encryption_set_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      s.id as from_id,
      v.id as to_id
    from
      azure_key_vault_key_version as v
      left join azure_compute_disk_encryption_set as s on s.active_key_url = v.key_uri_with_version
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

node "azure_key_vault_key_version_from_container_registry_node" {
  category = category.azure_container_registry

  sql = <<-EOQ
    select
      r.id as id,
      r.title as title,
      jsonb_build_object(
        'Name', r.name,
        'ID', r.id,
        'Provisioning State', r.provisioning_state,
        'Type', r.type,
        'Region', r.region,
        'Resource Group', r.resource_group,
        'Subscription ID', r.subscription_id
      ) as properties
    from
      azure_key_vault_key as k
      left join azure_container_registry as r on r.encryption -> 'keyVaultProperties' ->> 'keyIdentifier' = k.key_uri
      left join azure_key_vault_key_version as v on v.key_uri_with_version = k.key_uri_with_version
    where
      k.id = $1;
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_version_from_container_registry_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      r.id as from_id,
      v.id as to_id
    from
      azure_key_vault_key as k
      left join azure_container_registry as r on r.encryption -> 'keyVaultProperties' ->> 'keyIdentifier' = k.key_uri
      left join azure_key_vault_key_version as v on v.key_uri_with_version = k.key_uri_with_version
    where
      k.id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_version_from_sql_server_node" {
  category = category.sql_server

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
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Type', s.type,
        'Region', s.region,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_key_vault_key_version as v
      left join sql_server as s on v.key_uri_with_version = s.uri
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_version_from_sql_server_edge" {
  title = "encrypted with"

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
      s.id as from_id,
      v.id as to_id
    from
      azure_key_vault_key_version as v
      left join sql_server as s on v.key_uri_with_version = s.uri
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

node "azure_key_vault_key_from_eventhub_namespace_node" {
  category = category.azure_eventhub_namespace

  sql = <<-EOQ
    select
      n.id as id,
      n.title as title,
      jsonb_build_object(
        'Name', n.name,
        'ID', n.id,
        'Provisioning State', n.provisioning_state,
        'Type', n.type,
        'Region', n.region,
        'Resource Group', n.resource_group,
        'Subscription ID', n.subscription_id
      ) as properties
    from
      azure_eventhub_namespace as n,
      jsonb_array_elements(encryption -> 'keyVaultProperties') as p
      left join azure_key_vault_key as k on p ->> 'keyName' = k.name
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.resource_group = v.resource_group
      and k.resource_group = n.resource_group
      and k.id = $1;

  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_eventhub_namespace_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      n.id as from_id,
      k.id as to_id
    from
      azure_eventhub_namespace as n,
      jsonb_array_elements(encryption -> 'keyVaultProperties') as p
      left join azure_key_vault_key as k on p ->> 'keyName' = k.name
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.resource_group = v.resource_group
      and k.resource_group = n.resource_group
      and k.id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_version_from_storage_account_node" {
  category = category.azure_storage_account

  sql = <<-EOQ
    select
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Type', s.type,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_storage_account as s
      left join azure_key_vault_key_version as v on lower(s.encryption_key_vault_properties_key_current_version_id) = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_version_from_storage_account_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      s.id as from_id,
      v.id as to_id
    from
      azure_storage_account as s
      left join azure_key_vault_key_version as v on lower(s.encryption_key_vault_properties_key_current_version_id) = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

node "azure_key_vault_key_from_servicebus_namespace_node" {
  category = category.azure_servicebus_namespace

  sql = <<-EOQ
    select
      n.id as id,
      n.title as title,
      jsonb_build_object(
        'Name', n.name,
        'ID', n.id,
        'Provisioning State', n.provisioning_state,
        'Type', n.type,
        'Region', n.region,
        'Resource Group', n.resource_group,
        'Subscription ID', n.subscription_id
      ) as properties
    from
      azure_servicebus_namespace as n,
      jsonb_array_elements(encryption -> 'keyVaultProperties') as p
      left join azure_key_vault_key as k on p ->> 'keyName' = k.name
      left join azure_key_vault as v on v.name = k.vault_name
    where
      lower(k.resource_group) = lower(v.resource_group)
      and lower(k.resource_group) = lower(n.resource_group)
      and k.id = $1;

  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_servicebus_namespace_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      n.id as from_id,
      k.id as to_id
    from
      azure_servicebus_namespace as n,
      jsonb_array_elements(encryption -> 'keyVaultProperties') as p
      left join azure_key_vault_key as k on p ->> 'keyName' = k.name
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.resource_group = v.resource_group
      and k.resource_group = n.resource_group
      and k.id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_version_from_postgresql_server_node" {
  category = category.azure_postgresql_server

  sql = <<-EOQ
    select
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Type', s.type,
        'Region', s.region,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_postgresql_server as s,
      jsonb_array_elements(server_keys) as sk
      left join azure_key_vault_key_version as v on lower(sk ->> 'ServerKeyUri') = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_version_from_postgresql_server_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      s.id as from_id,
      v.id as to_id
    from
      azure_postgresql_server as s,
      jsonb_array_elements(server_keys) as sk
      left join azure_key_vault_key_version as v on lower(sk ->> 'ServerKeyUri') = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

