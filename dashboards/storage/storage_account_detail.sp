dashboard "storage_account_detail" {

  title         = "Azure Storage Account Detail"
  documentation = file("./dashboards/storage/docs/storage_account_detail.md")

  tags = merge(local.storage_common_tags, {
    type = "Detail"
  })

  input "storage_account_id" {
    title = "Select a storage account:"
    query = query.storage_account_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.storage_account_kind
      args  = [self.input.storage_account_id.value]
    }

    card {
      width = 2
      query = query.storage_account_access_tier
      args  = [self.input.storage_account_id.value]
    }

    card {
      width = 2
      query = query.storage_account_blob_soft_delete
      args  = [self.input.storage_account_id.value]
    }

    card {
      width = 2
      query = query.storage_account_blob_public_access
      args  = [self.input.storage_account_id.value]
    }

    card {
      width = 2
      query = query.storage_account_https_traffic
      args  = [self.input.storage_account_id.value]
    }

  }

  with "batch_accounts_for_storage_account" {
    query = query.batch_accounts_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "compute_disks_for_storage_account" {
    query = query.compute_disks_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "compute_snapshots_for_storage_account" {
    query = query.compute_snapshots_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "key_vault_keys_for_storage_account" {
    query = query.key_vault_keys_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "key_vault_vaults_for_storage_account" {
    query = query.key_vault_vaults_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "monitor_diagnostic_settings_for_storage_account" {
    query = query.monitor_diagnostic_settings_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "monitor_log_profiles_for_storage_account" {
    query = query.monitor_log_profiles_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "network_subnets_for_storage_account" {
    query = query.network_subnets_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  with "network_virtual_networks_for_storage_account" {
    query = query.network_virtual_networks_for_storage_account
    args  = [self.input.storage_account_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.batch_account
        args = {
          batch_account_ids = with.batch_accounts_for_storage_account.rows[*].batch_account_id
        }
      }

      node {
        base = node.compute_disk
        args = {
          compute_disk_ids = with.compute_disks_for_storage_account.rows[*].disk_id
        }
      }

      node {
        base = node.compute_snapshot
        args = {
          compute_snapshot_ids = with.compute_snapshots_for_storage_account.rows[*].snapshot_id
        }
      }

      node {
        base = node.key_vault_key
        args = {
          key_vault_key_ids = with.key_vault_keys_for_storage_account.rows[*].key_id
        }
      }

      node {
        base = node.key_vault_vault
        args = {
          key_vault_vault_ids = with.key_vault_vaults_for_storage_account.rows[*].vault_id
        }
      }

      node {
        base = node.monitor_diagnostic_setting
        args = {
          monitor_diagnostic_setting_ids = with.monitor_diagnostic_settings_for_storage_account.rows[*].monitor_diagnostic_settings_id
        }
      }

      node {
        base = node.monitor_log_profile
        args = {
          monitor_log_profile_ids = with.monitor_log_profiles_for_storage_account.rows[*].log_profile_id
        }
      }

      node {
        base = node.network_subnet
        args = {
          network_subnet_ids = with.network_subnets_for_storage_account.rows[*].subnet_id
        }
      }

      node {
        base = node.network_virtual_network
        args = {
          network_virtual_network_ids = with.network_virtual_networks_for_storage_account.rows[*].network_id
        }
      }

      node {
        base = node.storage_storage_account
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      node {
        base = node.storage_storage_container
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      node {
        base = node.storage_storage_queue
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      node {
        base = node.storage_storage_share_file
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      node {
        base = node.storage_storage_table
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      edge {
        base = edge.batch_account_to_storage_storage_account
        args = {
          batch_account_ids = with.batch_accounts_for_storage_account.rows[*].batch_account_id
        }
      }

      edge {
        base = edge.compute_disk_to_storage_storage_account
        args = {
          compute_disk_ids = with.compute_disks_for_storage_account.rows[*].disk_id
        }
      }

      edge {
        base = edge.compute_snapshot_to_storage_storage_account
        args = {
          compute_snapshot_ids = with.compute_snapshots_for_storage_account.rows[*].snapshot_id
        }
      }

      edge {
        base = edge.monitor_diagnostic_setting_to_storage_storage_account
        args = {
          monitor_diagnostic_setting_ids = with.monitor_diagnostic_settings_for_storage_account.rows[*].monitor_diagnostic_settings_id
        }
      }

      edge {
        base = edge.monitor_log_profile_to_storage_storage_account
        args = {
          monitor_log_profile_ids = with.monitor_log_profiles_for_storage_account.rows[*].log_profile_id
        }
      }

      edge {
        base = edge.network_subnet_to_network_virtual_network
        args = {
          network_subnet_ids = with.network_subnets_for_storage_account.rows[*].subnet_id
        }
      }

      edge {
        base = edge.storage_storage_account_to_key_vault_key
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      edge {
        base = edge.storage_storage_account_to_key_vault_vault
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      edge {
        base = edge.storage_storage_account_to_network_subnet
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      edge {
        base = edge.storage_storage_account_to_storage_storage_container
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      edge {
        base = edge.storage_storage_account_to_storage_storage_queue
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      edge {
        base = edge.storage_storage_account_to_storage_storage_share_file
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
      }

      edge {
        base = edge.storage_storage_account_to_storage_storage_table
        args = {
          storage_account_ids = [self.input.storage_account_id.value]
        }
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
        query = query.storage_account_overview
        args  = [self.input.storage_account_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.storage_account_tags
        args  = [self.input.storage_account_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "Blob Encryption Service"
        query = query.storage_account_blob_encryption_service
        args  = [self.input.storage_account_id.value]
      }

      table {
        title = "File Encryption Service"
        query = query.storage_account_file_encryption_service
        args  = [self.input.storage_account_id.value]
      }

      table {
        title = "SKU Details"
        query = query.storage_account_sku
        args  = [self.input.storage_account_id.value]
      }
    }

  }

  container {
    width = 12

    table {
      title = "Vitual Network Rules"
      query = query.storage_account_virtual_network_rules
      args  = [self.input.storage_account_id.value]
    }

  }

  container {
    width = 12

    table {
      title = "Blob Configurations"
      query = query.storage_account_blob_configurations
      args  = [self.input.storage_account_id.value]
    }

  }

  container {
    width = 12

    table {
      title = "Queue Logging"
      query = query.storage_account_queue_logging
      args  = [self.input.storage_account_id.value]
    }

  }

  container {
    width = 12

    table {
      title = "Blob Service Logging"
      query = query.storage_account_blob_logging
      args  = [self.input.storage_account_id.value]
    }

  }

}

query "storage_account_input" {
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

# card queries

query "storage_account_kind" {
  sql = <<-EOQ
    select
      'Kind' as label,
      kind as value
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ
}

query "storage_account_access_tier" {
  sql = <<-EOQ
    select
      'Access Tier' as label,
      access_tier as value
    from
      azure_storage_account
    where
      lower(id) = $1;
  EOQ
}

query "storage_account_blob_soft_delete" {
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
}

query "storage_account_blob_public_access" {
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
}

query "storage_account_https_traffic" {
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
}

# with queries

query "batch_accounts_for_storage_account" {
  sql = <<-EOQ
    select
      lower(b.id) as batch_account_id
    from
      azure_batch_account as b
      left join azure_storage_account as a on a.id = b.auto_storage ->> 'storageAccountId'
    where
      lower(a.id) = $1;
  EOQ
}

query "compute_disks_for_storage_account" {
  sql = <<-EOQ
    select
      lower(id) as disk_id
    from
      azure_compute_disk
    where
      lower(creation_data_storage_account_id) = $1;
  EOQ
}

query "compute_snapshots_for_storage_account" {
  sql = <<-EOQ
    select
      lower(id) as snapshot_id
    from
      azure_compute_snapshot
    where
      lower(storage_account_id) = $1;
  EOQ
}

query "key_vault_keys_for_storage_account" {
  sql = <<-EOQ
    select
      lower(key.id) as key_id
    from
      azure_storage_account as a
      left join azure_key_vault as k on a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
      left join azure_key_vault_key_version as v on lower(v.key_uri_with_version) = lower(a.encryption_key_vault_properties_key_current_version_id)
      left join azure_key_vault_key as key on lower(key.key_uri) = lower(v.key_uri)
    where
      key.id is not null
      and lower(a.id) = $1;
  EOQ
}

query "key_vault_vaults_for_storage_account" {
  sql = <<-EOQ
    select
      lower(k.id) as vault_id
    from
      azure_storage_account as a,
      azure_key_vault as k
    where
      a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
      and lower(a.id) = $1;
  EOQ
}

query "monitor_diagnostic_settings_for_storage_account" {
  sql = <<-EOQ
    select
      lower(id) as monitor_diagnostic_settings_id
    from
      azure_diagnostic_setting
    where
      lower(storage_account_id) = $1;
  EOQ
}

query "monitor_log_profiles_for_storage_account" {
  sql = <<-EOQ
    select
      lower(id) as log_profile_id
    from
      azure_log_profile
    where
      lower(storage_account_id) = $1;
  EOQ
}

query "network_subnets_for_storage_account" {
  sql = <<-EOQ
    select
      distinct(lower(r ->> 'id')) as subnet_id
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(id) = $1
  EOQ
}

query "network_virtual_networks_for_storage_account" {
  sql = <<-EOQ
    select
      distinct lower(split_part(r ->> 'id', '/subnets', 1)) as network_id
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(id) = $1
  EOQ
}

# table queries

query "storage_account_overview" {
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
}

query "storage_account_tags" {
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
}

query "storage_account_blob_encryption_service" {
  sql = <<-EOQ
    select
      encryption_services -> 'blob' ->> 'enabled' as "Enabled",
      encryption_services -> 'blob' ->> 'keyType' as "Key Type"
    from
      azure_storage_account
    where
      lower(id) = $1
  EOQ
}

query "storage_account_file_encryption_service" {
  sql = <<-EOQ
    select
      encryption_services -> 'file' ->> 'enabled' as "Enabled",
      encryption_services -> 'file' ->> 'keyType' as "Key Type"
    from
      azure_storage_account
    where
      lower(id) = $1
  EOQ
}

query "storage_account_sku" {
  sql = <<-EOQ
    select
      sku_name as "SKU Name",
      sku_tier as "SKU Tier"
    from
      azure_storage_account
    where
      lower(id) = $1
  EOQ
}

query "storage_account_virtual_network_rules" {
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
}

query "storage_account_blob_configurations" {
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
}

query "storage_account_queue_logging" {
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
}

query "storage_account_blob_logging" {
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
}