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
        node.azure_key_vault_key_node,
        node.azure_key_vault_key_to_key_vault_node,
        node.azure_key_vault_key_from_compute_disk_encryption_set_node,
        node.azure_key_vault_key_from_container_registry_node,
        node.azure_key_vault_key_from_sql_server_node,
        node.azure_key_vault_key_from_eventhub_namespace_node,
        node.azure_key_vault_key_from_storage_account_node,
        node.azure_key_vault_key_from_servicebus_namespace_node,
        node.azure_key_vault_key_from_postgresql_server_node
      ]

      edges = [
        edge.azure_key_vault_key_to_key_vault_edge,
        edge.azure_key_vault_key_from_compute_disk_encryption_set_edge,
        edge.azure_key_vault_key_from_container_registry_edge,
        edge.azure_key_vault_key_from_sql_server_edge,
        edge.azure_key_vault_key_from_eventhub_namespace_edge,
        edge.azure_key_vault_key_from_storage_account_edge,
        edge.azure_key_vault_key_from_servicebus_namespace_edge,
        edge.azure_key_vault_key_from_postgresql_server_edge
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

  container {
    width = 12


  }

}

query "azure_key_vault_key_input" {
  sql = <<-EOQ
    select
      k.title as label,
      k.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', k.resource_group,
        'region', k.region
      ) as tags
    from
      azure_key_vault_key as k,
      azure_subscription as s
    where
      k.subscription_id = s.subscription_id
    order by
      k.title;
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

category "azure_key_vault_key_no_link" {
  icon= "key"
}

node "azure_key_vault_key_node" {
  category = category.azure_key_vault_key_no_link

  sql = <<-EOQ
    select
      id,
      name as title,
      jsonb_build_object(
        'Key Name', name,
        'Key Id', id,
        'Vault Name', vault_name
      ) as properties
    from
      azure_key_vault_key
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_to_key_vault_node" {
  category = category.azure_key_vault

  sql = <<-EOQ
    select
      v.id as id,
      v.name as title,
      jsonb_build_object(
        'Name', v.name,
        'Key Id', v.id,
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

node "azure_key_vault_key_from_compute_disk_encryption_set_node" {
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
      azure_key_vault_key as k
      left join azure_compute_disk_encryption_set as s on s.active_key_url = k.key_uri_with_version
    where
      k.id = $1;
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_compute_disk_encryption_set_edge" {
  title = "encryption key"

  sql = <<-EOQ
    select
      s.id as from_id,
      k.id as to_id
    from
      azure_key_vault_key as k
      left join azure_compute_disk_encryption_set as s on s.active_key_url = k.key_uri_with_version
    where
      k.id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_from_container_registry_node" {
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
    where
      k.id = $1;
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_container_registry_edge" {
  title = "encryption key"

  sql = <<-EOQ
    select
      r.id as from_id,
      k.id as to_id
    from
      azure_key_vault_key as k
      left join azure_container_registry as r on r.encryption -> 'keyVaultProperties' ->> 'keyIdentifier' = k.key_uri
    where
      k.id = $1;
  EOQ

  param "id" {}
}

node "azure_key_vault_key_from_sql_server_node" {
  category = category.azure_sql_server

  sql = <<-EOQ
    with sql_server as (
      select
        split_part(ep ->> 'serverKeyName','_',1) as key_vault_name,
        split_part(ep ->> 'serverKeyName','_',2) as key_vault_key_name,
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
      azure_key_vault_key as k
      left join sql_server as s on k.name = s.key_vault_key_name
    where
      k.id = '/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/demo/providers/Microsoft.KeyVault/vaults/test-delete90/keys/tets56';
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_sql_server_edge" {
  title = "encryption key"

  sql = <<-EOQ
    with sql_server as (
      select
        split_part(ep ->> 'serverKeyName','_',1) as key_vault_name,
        split_part(ep ->> 'serverKeyName','_',2) as key_vault_key_name,
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
      k.id as to_id
    from
      azure_key_vault_key as k
      left join sql_server as s on k.name = s.key_vault_key_name
    where
      k.id = '/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/demo/providers/Microsoft.KeyVault/vaults/test-delete90/keys/tets56';
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
  title = "encryption key"

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

node "azure_key_vault_key_from_storage_account_node" {
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
      left join azure_key_vault_key as k on s.encryption_key_vault_properties_key_current_version_id = key_uri_with_version
    where
      k.id = $1;
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_storage_account_edge" {
  title = "encryption key"

  sql = <<-EOQ
    select
      s.id as from_id,
      k.id as to_id
    from
      azure_storage_account as s
      left join azure_key_vault_key as k on s.encryption_key_vault_properties_key_current_version_id = key_uri_with_version
    where
      k.id = $1;
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
      k.resource_group = v.resource_group
      and k.resource_group = n.resource_group
      and k.id = $1;

  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_servicebus_namespace_edge" {
  title = "encryption key"

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

node "azure_key_vault_key_from_postgresql_server_node" {
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
      left join azure_key_vault_key as k on sk ->> 'ServerKeyUri' = k.key_uri_with_version
    where
      k.id = $1;
  EOQ

  param "id" {}
}

edge "azure_key_vault_key_from_postgresql_server_edge" {
  title = "encryption key"

  sql = <<-EOQ
    select
      s.id as from_id,
      k.id as to_id
    from
      azure_postgresql_server as s,
      jsonb_array_elements(server_keys) as sk
      left join azure_key_vault_key as k on sk ->> 'ServerKeyUri' = k.key_uri_with_version
    where
      k.id = $1;
  EOQ

  param "id" {}
}

