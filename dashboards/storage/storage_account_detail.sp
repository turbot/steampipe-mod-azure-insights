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
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.storage_account_access_tier
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.storage_account_blob_soft_delete
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.storage_account_blob_public_access
      args = {
        id = self.input.storage_account_id.value
      }
    }

    card {
      width = 2
      query = query.storage_account_https_traffic
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

      with "batch_accounts" {
        sql = <<-EOQ
          select
            lower(b.id) as batch_account_id
          from
            azure_batch_account as b
            left join azure_storage_account as a on a.id = b.auto_storage ->> 'storageAccountId'
          where
            lower(a.id) = $1;
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
            lower(creation_data_storage_account_id) = $1;
        EOQ

        args = [self.input.storage_account_id.value]
      }

      with "compute_snapshots" {
        sql = <<-EOQ
          select
            lower(id) as snapshot_id
          from
            azure_compute_snapshot
          where
            lower(storage_account_id) = $1;
        EOQ

        args = [self.input.storage_account_id.value]
      }

      with "key_vault_keys" {
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

        args = [self.input.storage_account_id.value]
      }

      with "key_vaults" {
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

        args = [self.input.storage_account_id.value]
      }

      with "monitor_diagnostic_settings" {
        sql = <<-EOQ
          select
            lower(id) as monitor_diagnostic_settings_id
          from
            azure_diagnostic_setting
          where
            lower(storage_account_id) = $1;
        EOQ

        args = [self.input.storage_account_id.value]
      }

      with "monitor_log_profiles" {
        sql = <<-EOQ
          select
            lower(id) as log_profile_id
          from
            azure_log_profile
          where
            lower(storage_account_id) = $1;
        EOQ

        args = [self.input.storage_account_id.value]
      }

      with "network_subnets" {
        sql = <<-EOQ
          select
            distinct(lower(r ->> 'id')) as subnet_id
          from
            azure_storage_account,
            jsonb_array_elements(virtual_network_rules) as r
          where
            lower(id) = $1
        EOQ

        args = [self.input.storage_account_id.value]
      }

      with "network_virtual_networks" {
        sql = <<-EOQ
            select
              distinct lower(split_part(r ->> 'id', '/subnets', 1)) as network_id
            from
              azure_storage_account,
              jsonb_array_elements(virtual_network_rules) as r
            where
              lower(id) = $1
          EOQ

        args = [self.input.storage_account_id.value]
      }

      nodes = [
        node.batch_account,
        node.compute_disk,
        node.compute_snapshot,
        node.key_vault_key,
        node.key_vault,
        node.monitor_diagnostic_setting,
        node.monitor_log_profile,
        node.network_subnet,
        node.network_virtual_network,
        node.storage_container,
        node.storage_queue,
        node.storage_share_file,
        node.storage_storage_account,
        node.storage_table,
      ]

      edges = [
        edge.batch_account_to_storage_storage_account,
        edge.compute_disk_to_storage_storage_account,
        edge.compute_snapshot_to_storage_storage_account,
        edge.monitor_diagnostic_setting_to_storage_storage_account,
        edge.monitor_log_profile_to_storage_storage_account,
        edge.network_subnet_to_network_virtual_network,
        edge.storage_storage_account_to_key_vault_key,
        edge.storage_storage_account_to_key_vault,
        edge.storage_storage_account_to_network_subnet,
        edge.storage_storage_account_to_storage_container,
        edge.storage_storage_account_to_storage_queue,
        edge.storage_storage_account_to_storage_share_file,
        edge.storage_storage_account_to_storage_table,
      ]

      args = {
        batch_account_ids              = with.batch_accounts.rows[*].batch_account_id
        compute_disk_ids               = with.compute_disks.rows[*].disk_id
        compute_snapshot_ids           = with.compute_snapshots.rows[*].snapshot_id
        key_vault_ids                  = with.key_vaults.rows[*].vault_id
        key_vault_key_ids              = with.key_vault_keys.rows[*].key_id
        monitor_diagnostic_setting_ids = with.monitor_diagnostic_settings.rows[*].monitor_diagnostic_settings_id
        monitor_log_profile_ids        = with.monitor_log_profiles.rows[*].log_profile_id
        network_subnet_ids             = with.network_subnets.rows[*].subnet_id
        storage_account_ids            = [self.input.storage_account_id.value]
        virtual_network_ids            = with.network_virtual_networks.rows[*].network_id
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
        args = {
          id = self.input.storage_account_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.storage_account_tags
        args = {
          id = self.input.storage_account_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Blob Encryption Service"
        query = query.storage_account_blob_encryption_service
        args = {
          id = self.input.storage_account_id.value
        }
      }

      table {
        title = "File Encryption Service"
        query = query.storage_account_file_encryption_service
        args = {
          id = self.input.storage_account_id.value
        }
      }

      table {
        title = "SKU Details"
        query = query.storage_account_sku
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
      query = query.storage_account_virtual_network_rules
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Blob Configurations"
      query = query.storage_account_blob_configurations
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Queue Logging"
      query = query.storage_account_queue_logging
      args = {
        id = self.input.storage_account_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Blob Service Logging"
      query = query.storage_account_blob_logging
      args = {
        id = self.input.storage_account_id.value
      }
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
}

query "storage_account_sku" {
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
}





