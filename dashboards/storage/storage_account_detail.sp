dashboard "azure_storage_account_detail" {

  title         = "Azure Storage Account Detail"
  documentation = file("./dashboards/storage/docs/storage_account_detail.md")

  tags = merge(local.storage_common_tags, {
    type = "Detail"
  })

  input "storage_account_id" {
    title = "Select a storage account:"
    query = query.azure_storage_account_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_storage_account_kind
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_access_tier
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_blob_soft_delete
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_blob_public_access
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_https_traffic
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "compute_snapshots" {
        sql = <<-EOQ
          select
            lower(id) as snapshot_id
          from
            azure_compute_snapshot
          where
            lower(storage_account_id) = lower($1);
        EOQ

        args = [self.input.storage_account_id.value]
      }

      with "compute_disks" {
        sql = <<-EOQ
          select
            lower(id) as disk_id
          from
            azure_compute_disk
          where
            lower(creation_data_storage_account_id) = lower($1);
        EOQ

        args = [self.input.storage_account_id.value]
      }

      with "network_subnets" {
        sql = <<-EOQ
          with subnet_list as (
            select
              r ->> 'id' as subnet_id
            from
              azure_storage_account,
              jsonb_array_elements(virtual_network_rules) as r
            where
              lower(id) = lower($1)
          )
          select
            lower(id) as network_subnet_id
          from
            subnet_list as l
            left join azure_subnet as s on lower(l.subnet_id) = lower(s.id);
        EOQ

        args = [self.input.subnet_id.value]
      }

      nodes = [
        node.storage_storage_account,
        node.log_profile,
        node.compute_snapshot,
        node.diagnostic_setting,
        node.compute_disk,
        node.network_subnet,
        node.network_virtual_network,
        node.storage_storage_table,
        node.storage_storage_queue,
        node.storage_storage_container,
        node.azure_storage_account_to_storage_share_file_node,
        node.azure_storage_account_to_key_vault_node,
        node.azure_storage_account_key_vault_to_key_vault_key_node,
        node.azure_storage_account_from_batch_account_node
      ]

      edges = [
        edge.log_profile_to_storage_storage_account
        edge.compute_snapshot_to_storage_storage_account,
        edge.diagnostic_setting_to_storage_storage_account,
        edge.compute_disk_to_storage_storage_account,
        edge.network_subnet_to_storage_storage_account,
        edge.storage_storage_account_subnet_to_virtual_network,
        edge.storage_storage_account_to_storage_storage_table,
        edge.azure_storage_account_to_storage_queue_edge,
        edge.azure_storage_account_to_storage_container_edge,
        edge.azure_storage_account_to_storage_share_file_edge,
        edge.azure_storage_account_to_key_vault_edge,
        edge.azure_storage_account_key_vault_to_key_vault_key_edge,
        edge.azure_storage_account_from_batch_account_edge
      ]

      args = {
        storage_account_ids = [self.input.storage_account_id.value]
        id                  = self.input.storage_account_id.value
        compute_snapshot_ids = with.compute_snapshots.rows[*].snapshot_id
        compute_disk_ids = with.compute_disks.rows[*].disk_id
        network_subnet_ids = with.network_subnets.rows[*].network_subnet_id
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
        query = query.azure_storage_account_overview
        args = {
          id = self.input.storage_account_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_storage_account_tags
        args = {
          id = self.input.storage_account_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Blob Encryption Service"
        query = query.azure_storage_account_blob_encryption_service
        args = {
          id = self.input.storage_account_id.value
        }
      }

      table {
        title = "File Encryption Service"
        query = query.azure_storage_account_file_encryption_service
        args = {
          id = self.input.storage_account_id.value
        }
      }

      table {
        title = "SKU Details"
        query = query.azure_storage_account_sku
        args = {
          id = self.input.storage_account_id.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Vitual Network Rules"
      query = query.azure_storage_account_virtual_network_rules
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Blob Configurations"
      query = query.azure_storage_account_blob_configurations
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Queue Logging"
      query = query.azure_storage_account_queue_logging
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Blob Service Logging"
      query = query.azure_storage_account_blob_logging
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

}

query "azure_storage_account_input" {
  sql = <<-EOQ
    select
      sa.title as label,
      lower(sa.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', sa.resource_group,
        'region', sa.region
      ) as tags
    from
      azure_storage_account as sa,
      azure_subscription as s
    where
      lower(sa.subscription_id) = lower(s.subscription_id)
    order by
      sa.title;
  EOQ
}

query "azure_storage_account_kind" {
  sql = <<-EOQ
    select
      'Kind' as label,
      kind as value
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "azure_storage_account_access_tier" {
  sql = <<-EOQ
    select
      'Access Tier' as label,
      access_tier as value
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "azure_storage_account_blob_soft_delete" {
  sql = <<-EOQ
    select
      'Blob Soft Delete' as label,
      case when blob_soft_delete_enabled then 'Enabled' else 'Disabled' end as value,
      case when blob_soft_delete_enabled then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "azure_storage_account_blob_public_access" {
  sql = <<-EOQ
    select
      'Blob Public Access' as label,
      case when allow_blob_public_access then 'Enabled' else 'Disabled' end as value,
      case when blob_soft_delete_enabled then 'alert' else 'ok' end as type
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "azure_storage_account_https_traffic" {
  sql = <<-EOQ
    select
      'HTTPS' as label,
      case when enable_https_traffic_only then 'Enabled' else 'Disabled' end as value,
      case when enable_https_traffic_only then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "azure_storage_account_unrestricted_network_access" {
  sql = <<-EOQ
    select
      'Unrestricted Network Access' as label,
      case when network_rule_default_action <> 'Deny' then 'Enabled' else 'Disabled' end as value,
      case when network_rule_default_action <> 'Deny' then 'alert' else 'ok' end as type
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "azure_storage_account_infrastructure_encryption" {
  sql = <<-EOQ
    select
      'Infrastructure Encryption' as label,
      case when require_infrastructure_encryption then 'Enabled' else 'Disabled' end as value,
      case when require_infrastructure_encryption then 'ok' else 'alert' end as type
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "azure_storage_account_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      minimum_tls_version as "Minimum TLS Version",
      title as "Title",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_storage_account
    where
      lower(id) = $1
  EOQ

  param "id" {}
}

query "azure_storage_account_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_storage_account,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_storage_account_blob_encryption_service" {
  sql = <<-EOQ
    select
      encryption_services -> 'blob' ->> 'enabled' as "Enabled",
      encryption_services -> 'blob' ->> 'keyType' as "Key Type"
    from
      azure_storage_account
    where
      lower(id) = $1
    EOQ

  param "id" {}
}

query "azure_storage_account_file_encryption_service" {
  sql = <<-EOQ
    select
      encryption_services -> 'file' ->> 'enabled' as "Enabled",
      encryption_services -> 'file' ->> 'keyType' as "Key Type"
    from
      azure_storage_account
    where
      lower(id) = $1
    EOQ

  param "id" {}
}

query "azure_storage_account_sku" {
  sql = <<-EOQ
    select
      sku_name as "SKU Name",
      sku_tier as "SKU Tier"
    from
      azure_storage_account
    where
      id = $1
    EOQ

  param "id" {}
}

query "azure_storage_account_virtual_network_rules" {
  sql = <<-EOQ
    select
      vnr ->> 'action' as "Action",
      vnr ->> 'id' as "ID",
      vnr ->> 'state' as "State"
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as vnr
    where
      lower(id) = $1
    EOQ

  param "id" {}
}

query "azure_storage_account_blob_configurations" {
  sql = <<-EOQ
    select
      blob_container_soft_delete_enabled  as "Blob Container Soft Delete Enabled",
      blob_container_soft_delete_retention_days as "Blob Container Soft Delete Detention Days",
      blob_restore_policy_enabled as "Blob Restore Policy Enabled",
      blob_restore_policy_days as "Blob Restore Policy Days",
      blob_versioning_enabled as "Blob Versioning Enabled",
      blob_change_feed_enabled as "Blob Change Feed Enabled",
      blob_soft_delete_retention_days as "Blob Soft Delete Retention Days"
    from
      azure_storage_account
    where
      lower(id) = $1
    EOQ

  param "id" {}
}

query "azure_storage_account_queue_logging" {
  sql = <<-EOQ
    select
      queue_logging_delete  as "Queue Logging Delete",
      queue_logging_read as "Queue Logging Read",
      queue_logging_retention_days as "Queue Logging Retention Days",
      queue_logging_retention_enabled as "Queue Logging Retention Enabled",
      queue_logging_write as "Queue Logging Write",
      queue_logging_version as "Queue Logging Version"
    from
      azure_storage_account
    where
      lower(id) = $1
    EOQ

  param "id" {}
}

query "azure_storage_account_blob_logging" {
  sql = <<-EOQ
    select
      blob_service_logging ->> 'Delete' as "Delete",
      blob_service_logging ->>'Read' as "Read",
      blob_service_logging ->> 'Write' as "Write",
      blob_service_logging -> 'RetentionPolicy' ->> 'Enabled' as "Retention Policy Enabled",
      blob_service_logging -> 'RetentionPolicy' ->> 'Days' as "Retention Days"
    from
      azure_storage_account
    where
      lower(id) = $1
    EOQ

  param "id" {}
}

node "log_profile" {
  category = category.log_profile

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_log_profile
    where
      lower(storage_account_id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "log_profile_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(storage_account_id) as to_id
    from
      azure_log_profile
    where
      lower(storage_account_id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "compute_snapshot_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(storage_account_id) as to_id
    from
      azure_compute_snapshot
    where
      lower(storage_account_id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

node "diagnostic_setting" {
  category = category.azure_diagnostic_setting

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_diagnostic_setting
    where
      lower(storage_account_id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "diagnostic_setting_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(storage_account_id) as to_id
    from
      azure_diagnostic_setting
    where
      lower(storage_account_id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_subnet_to_virtual_network" {
  title = "virtual network"

  sql = <<-EOQ
    with vn_list as (
      select
        r ->> 'id' as subnet_id,
        split_part(r ->> 'id', '/subnets', 1) as vn_id
      from
        azure_storage_account,
        jsonb_array_elements(virtual_network_rules) as r
      where
        id = any($1)
    )
    select
      lower(l.subnet_id) as from_id,
      lower(l.vn_id) as to_id
    from
      vn_list as l
      left join azure_virtual_network as n on lower(n.id) = lower(l.vn_id);
  EOQ

  param "storage_account_ids" {}
}

node "storage_storage_table" {
  category = category.azure_storage_table

  sql = <<-EOQ
    select
      lower(t.id) as id,
      t.title as title,
      jsonb_build_object(
        'Name', t.name,
        'ID', t.id,
        'Type', t.type,
        'Region', t.region,
        'Resource Group', t.resource_group,
        'Subscription ID', t.subscription_id
      ) as properties
    from
      azure_storage_account as a
      left join azure_storage_table as t on t.storage_account_name = a.name
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_to_storage_storage_table" {
  title = "storage table"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(t.id) as to_id
    from
      azure_storage_account as a
      left join azure_storage_table as t on t.storage_account_name = a.name
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_storage_table" {}
}

node "storage_storage_queue" {
  category = category.azure_storage_queue

  sql = <<-EOQ
    select
      lower(q.id) as id,
      q.title as title,
      jsonb_build_object(
        'Name', q.name,
        'ID', q.id,
        'Region', q.region,
        'Type', q.type,
        'Resource Group', q.resource_group,
        'Subscription ID', q.subscription_id
      ) as properties
    from
      azure_storage_account as a
      left join azure_storage_queue as q on q.storage_account_name = a.name
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_storage_table" {}
}

edge "azure_storage_account_to_storage_queue_edge" {
  title = "storage queue"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(q.id) as to_id
    from
      azure_storage_account as a
      left join azure_storage_queue as q on q.storage_account_name = a.name
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_storage_table" {}
}

node "storage_storage_container" {
  category = category.azure_storage_container

  sql = <<-EOQ
    select
      lower(c.id) as id,
      c.title as title,
      jsonb_build_object(
        'Name', c.name,
        'ID', c.id,
        'Type', c.type,
        'Resource Group', c.resource_group,
        'Subscription ID', c.subscription_id
      ) as properties
    from
      azure_storage_container as c
      left join azure_storage_account as a on a.name = c.account_name
      and a.resource_group = c.resource_group
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_storage_table" {}
}

edge "azure_storage_account_to_storage_container_edge" {
  title = "storage container"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(c.id) as to_id
   from
      azure_storage_container as c
      left join azure_storage_account as a on a.name = c.account_name
      and a.resource_group = c.resource_group
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

node "azure_storage_account_to_storage_share_file_node" {
  category = category.azure_storage_share_file

  sql = <<-EOQ
    select
      lower(f.id) as id,
      f.title as title,
      jsonb_build_object(
        'Name', f.name,
        'ID', f.id,
        'Type', f.type,
        'Resource Group', f.resource_group,
        'Subscription ID', f.subscription_id
      ) as properties
    from
      azure_storage_share_file as f
      left join azure_storage_account as a on a.name = f.storage_account_name
      and a.resource_group = f.resource_group
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_storage_account_to_storage_share_file_edge" {
  title = "storage share file"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(f.id) as to_id
    from
      azure_storage_share_file as f
      left join azure_storage_account as a on a.name = f.storage_account_name
      and a.resource_group = f.resource_group
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

node "azure_storage_account_to_key_vault_node" {
  category = category.key_vault

  sql = <<-EOQ
    select
      lower(k.id) as id,
      k.title as title,
      jsonb_build_object(
        'Name', k.name,
        'ID', k.id,
        'Type', k.type,
        'Resource Group', k.resource_group,
        'Subscription ID', k.subscription_id
      ) as properties
    from
      azure_storage_account as a,
      azure_key_vault as k
    where
      a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
      and lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_storage_account_to_key_vault_edge" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(k.id) as to_id
    from
      azure_storage_account as a
      left join azure_key_vault as k on a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

node "azure_storage_account_key_vault_to_key_vault_key_node" {
  category = category.key_vault_key

  sql = <<-EOQ
    select
      lower(key.id) as id,
      key.name as title,
      jsonb_build_object(
        'Name', key.name,
        'Key ID', key.id,
        'Type', key.type,
        'Resource Group', key.resource_group,
        'Subscription ID', key.subscription_id
      ) as properties
   from
      azure_storage_account as a
      left join azure_key_vault as k on a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
      left join azure_key_vault_key_version as v on lower(v.key_uri_with_version) = lower(a.encryption_key_vault_properties_key_current_version_id)
      left join azure_key_vault_key as key on lower(key.key_uri) = lower(v.key_uri)
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_storage_account_key_vault_to_key_vault_key_edge" {
  title = "key"

  sql = <<-EOQ
    select
      lower(k.id )as from_id,
      lower(key.id) as to_id
   from
      azure_storage_account as a
      left join azure_key_vault as k on a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
      left join azure_key_vault_key_version as v on lower(v.key_uri_with_version) = lower(a.encryption_key_vault_properties_key_current_version_id)
      left join azure_key_vault_key as key on lower(key.key_uri) = lower(v.key_uri)
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

node "azure_storage_account_from_batch_account_node" {
  category = category.azure_batch_account

  sql = <<-EOQ
    select
      lower(b.id) as id,
      b.title as title,
      jsonb_build_object(
        'Name', b.name,
        'ID', b.id,
        'Type', b.type,
        'Resource Group', b.resource_group,
        'Subscription ID', b.subscription_id
      ) as properties
    from
      azure_batch_account as b
      left join azure_storage_account as a on a.id = b.auto_storage ->> 'storageAccountId'
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_storage_account_from_batch_account_edge" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(b.id) as from_id,
      lower(a.id) as to_id
   from
      azure_batch_account as b
      left join azure_storage_account as a on a.id = b.auto_storage ->> 'storageAccountId'
    where
      lower(a.id) = lower($1);
  EOQ

  param "id" {}
}