dashboard "azure_key_vault_key_detail" {

  title = "Azure Key Vault Key Detail"

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })

  input "id" {
    title = "Select a key:"
    sql   = query.azure_key_vault_key_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_key_vault_key_vault_name
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_key_vault_key_state
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
        query = query.azure_key_vault_key_overview
        args = {
          id = self.input.id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_key_vault_key_tags
        args = {
          id = self.input.id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Key Operations"
        query = query.azure_key_vault_key_key_operations
        args = {
          id = self.input.id.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Key Details"
      query = query.azure_key_vault_key_key_details
      args = {
        id = self.input.id.value
      }
    }

  }

}

query "azure_key_vault_key_input" {
  sql = <<-EOQ
    select
      title as label,
      id as value,
      json_build_object(
        'resource_group', resource_group,
        'region', region
      ) as tags
    from
      azure_key_vault_key
    order by
      title;
  EOQ
}

query "azure_key_vault_key_vault_name" {
  sql = <<-EOQ
    select
      'Vault Name' as label,
      vault_name as value
    from
      azure_key_vault_key
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_key_vault_key_state" {
  sql = <<-EOQ
    select
      'Key State' as label,
      case when enabled then 'enabled' else 'disabled' end as value,
      case when enabled then 'ok' else 'alert' end as type
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
      created_at as "Created At",
      expires_at as "Expires At",
      title as "Title",
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
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_key_vault_key,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_key_vault_key_key_operations" {
  sql = <<-EOQ
    select
      op as "Operations"
    from
      azure_key_vault_key as kvk,
      jsonb_array_elements_text(key_ops) as op
    where
      id = $1;
    EOQ

  param "id" {}
}

query "azure_key_vault_key_key_details" {
  sql = <<-EOQ
    select
      key_size as "Size",
      key_type as "Type",
      key_uri as "URI",
      key_uri_with_version as "URI with Version"
    from
      azure_key_vault_key
    where
      id = $1;
    EOQ

  param "id" {}
}
