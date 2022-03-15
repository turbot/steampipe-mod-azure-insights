dashboard "azure_storage_account_detail" {

  title          = "Azure Storage Account Detail"
   documentation = file("./dashboards/storage/docs/storage_account_detail.md")

  tags = merge(local.storage_common_tags, {
    type = "Detail"
  })

  input "id" {
    title = "Select a account:"
    sql   = query.azure_storage_account_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_storage_account_kind
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_access_tier
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_blob_soft_delete
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_blob_public_access
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_storage_account_https_traffic
      args = {
        id = self.input.id.value
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
          id = self.input.id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_storage_account_tags
        args = {
          id = self.input.id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Blob Encryption Service"
        query = query.azure_storage_account_blob_encryption_service
        args = {
          id = self.input.id.value
        }
      }

      table {
        title = "File Encryption Service"
        query = query.azure_storage_account_file_encryption_service
        args = {
          id = self.input.id.value
        }
      }

      table {
        title = "SKU Details"
        query = query.azure_storage_account_sku
        args = {
          id = self.input.id.value
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
        id = self.input.id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Blob Configurations"
      query = query.azure_storage_account_blob_configurations
      args = {
        id = self.input.id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Queue Logging"
      query = query.azure_storage_account_queue_logging
      args = {
        id = self.input.id.value
      }
    }

  }

   container {
    width = 12

    table {
      title = "Blob Servcie Logging"
      query = query.azure_storage_account_blob_logging
      args = {
        id = self.input.id.value
      }
    }

  }

}

query "azure_storage_account_input" {
  sql = <<-EOQ
    select
      title as label,
      id as value,
      json_build_object(
        'resource_group', resource_group,
        'region', region
      ) as tags
    from
      azure_storage_account
    order by
      title;
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
      id = $1;
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
      id = $1;
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
      id = $1;
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
      id = $1;
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
      id = $1;
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
      id = $1;
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
      id = $1;
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
      id = $1
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
      id = $1
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
      id = $1
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
      id = $1
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
      id = $1
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
      id = $1
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
      id = $1
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
      id = $1
    EOQ

  param "id" {}
}


