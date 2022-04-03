dashboard "azure_key_vault_detail" {

  title         = "Azure Key Vault Detail"
  documentation = file("./dashboards/keyvault/docs/key_vault_detail.md")

  tags = merge(local.keyvault_common_tags, {
    type = "Detail"
  })

  input "key_vault_id" {
    title = "Select a key vault:"
    query = query.azure_key_vault_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_key_vault_soft_delete_retention_in_days
      args = {
        id = self.input.key_vault_id.value
      }
    }

    card {
      width = 2
      query = query.azure_key_vault_public_network_access_enabled
      args = {
        id = self.input.key_vault_id.value
      }
    }

    card {
      width = 2
      query = query.azure_key_vault_purge_protection_status
      args = {
        id = self.input.key_vault_id.value
      }
    }

    card {
      width = 2
      query = query.azure_key_vault_soft_delete_status
      args = {
        id = self.input.key_vault_id.value
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
        query = query.azure_key_vault_overview
        args = {
          id = self.input.key_vault_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_key_vault_tags
        args = {
          id = self.input.key_vault_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "SKU Details"
        query = query.azure_key_vault_sku
        args = {
          id = self.input.key_vault_id.value
        }
      }

      table {
        title = "Vault Usages"
        query = query.azure_key_vault_usage
        args = {
          id = self.input.key_vault_id.value
        }
      }

    }

  }

  container {
    width = 12

    table {
      title = "Access Policies"
      query = query.azure_key_vault_access_policies
      args = {
        id = self.input.key_vault_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Access Details"
      query = query.azure_key_vault_network_acls
      args = {
        id = self.input.key_vault_id.value
      }
    }

  }

}

query "azure_key_vault_input" {
  sql = <<-EOQ
    select
      v.title as label,
      v.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', v.resource_group,
        'region', v.region
      ) as tags
    from
      azure_key_vault as v,
      azure_subscription as s
    where
      v.subscription_id = s.subscription_id
    order by
      v.title;
  EOQ
}

query "azure_key_vault_purge_protection_status" {
  sql = <<-EOQ
    select
      'Purge Protection' as label,
      case when purge_protection_enabled then 'Enabled' else 'Disabled' end as value,
      case when purge_protection_enabled then 'ok' else 'alert' end as type
    from
      azure_key_vault
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_key_vault_public_network_access_enabled" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when network_acls is null or network_acls ->> 'defaultAction' != 'Deny' then 'Enabled' else 'Disabled' end as value,
      case when network_acls is null or network_acls ->> 'defaultAction' != 'Deny' then 'alert' else 'ok' end as type
    from
      azure_key_vault
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_key_vault_soft_delete_status" {
  sql = <<-EOQ
    select
      'Soft Delete' as label,
      case when soft_delete_enabled then 'Enabled' else 'Disabled' end as value,
      case when soft_delete_enabled then 'ok' else 'alert' end as type
    from
      azure_key_vault
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_key_vault_soft_delete_retention_in_days" {
  sql = <<-EOQ
    select
      'Soft Delete Retention Days' as label,
      soft_delete_retention_in_days as value
    from
      azure_key_vault
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_key_vault_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      vault_uri as "Vault URI",
      type as "Type",
      cloud_environment as "Cloud Environment",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      tenant_id as "Tenant ID",
      id as "ID"
    from
      azure_key_vault
    where
      id = $1
  EOQ

  param "id" {}
}

query "azure_key_vault_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_key_vault,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_key_vault_access_policies" {
  sql = <<-EOQ
    select
      p ->> 'objectId' as "User Object ID",
      p ->> 'permissionsCertificates' as "Certificate Permissions",
      p ->> 'permissionsKeys' as "Key Permissions",
      p ->> 'permissionsSecrets' as "Secret Permissions",
      p ->> 'permissionsStorage' as "Storage Permissions",
      p ->> 'tenantId' as "Tenant ID"
    from
      azure_key_vault,
      jsonb_array_elements(access_policies) as p
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_key_vault_sku" {
  sql = <<-EOQ
    select
      sku_family as "SKU Family",
      sku_name as "SKU Name"
    from
      azure_key_vault
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_key_vault_network_acls" {
  sql = <<-EOQ
    select
      network_acls ->> 'bypass' as "Bypass",
      network_acls ->> 'defaultAction' as "Default Action",
      network_acls ->> 'ipRules' as "IP Rules",
      network_acls ->> 'virtualNetworkRules' as "Virtual Network Rules"
    from
      azure_key_vault
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_key_vault_usage" {
  sql = <<-EOQ
    select
      enabled_for_deployment as "Enabled For Deployment",
      enabled_for_disk_encryption as "Enabled For Disk Encryption",
      enabled_for_template_deployment as "Enabled For Template Deployment"
    from
      azure_key_vault
    where
      id = $1;
  EOQ

  param "id" {}
}
