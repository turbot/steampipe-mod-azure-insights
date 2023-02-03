dashboard "key_vault_detail" {

  title         = "Azure Key Vault Detail"
  documentation = file("./dashboards/keyvault/docs/key_vault_detail.md")

  tags = merge(local.keyvault_common_tags, {
    type = "Detail"
  })

  input "key_vault_id" {
    title = "Select a key vault:"
    query = query.key_vault_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.key_vault_soft_delete_retention_in_days
      args  = [self.input.key_vault_id.value]
    }

    card {
      width = 3
      query = query.key_vault_public_network_access_enabled
      args  = [self.input.key_vault_id.value]
    }

    card {
      width = 3
      query = query.key_vault_purge_protection_status
      args  = [self.input.key_vault_id.value]
    }

    card {
      width = 3
      query = query.key_vault_soft_delete_status
      args  = [self.input.key_vault_id.value]
    }

  }

  with "key_vault_keys_for_key_vault" {
    query = query.key_vault_keys_for_key_vault
    args  = [self.input.key_vault_id.value]
  }

  with "network_subnets_for_key_vault" {
    query = query.network_subnets_for_key_vault
    args  = [self.input.key_vault_id.value]
  }

  with "network_virtual_networks_for_key_vault" {
    query = query.network_virtual_networks_for_key_vault
    args  = [self.input.key_vault_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.key_vault_key
        args = {
          key_vault_key_ids = with.key_vault_keys_for_key_vault.rows[*].key_id
        }
      }

      node {
        base = node.key_vault_secret
        args = {
          key_vault_vault_ids = [self.input.key_vault_id.value]
        }
      }

      node {
        base = node.key_vault_vault
        args = {
          key_vault_vault_ids = [self.input.key_vault_id.value]
        }
      }

      node {
        base = node.network_subnet
        args = {
          network_subnet_ids = with.network_subnets_for_key_vault.rows[*].subnet_id
        }
      }

      node {
        base = node.network_virtual_network
        args = {
          network_virtual_network_ids = with.network_virtual_networks_for_key_vault.rows[*].virtual_network_id
        }
      }

      edge {
        base = edge.key_vault_to_key_vault_key
        args = {
          key_vault_vault_ids = [self.input.key_vault_id.value]
        }
      }

      edge {
        base = edge.key_vault_to_key_vault_secret
        args = {
          key_vault_vault_ids = [self.input.key_vault_id.value]
        }
      }

      edge {
        base = edge.key_vault_to_subnet
        args = {
          key_vault_vault_ids = [self.input.key_vault_id.value]
        }
      }

      edge {
        base = edge.network_subnet_to_network_virtual_network
        args = {
          network_subnet_ids = with.network_subnets_for_key_vault.rows[*].subnet_id
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
        query = query.key_vault_overview
        args  = [self.input.key_vault_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.key_vault_tags
        args  = [self.input.key_vault_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "SKU Details"
        query = query.key_vault_sku
        args  = [self.input.key_vault_id.value]
      }

      table {
        title = "Vault Usages"
        query = query.key_vault_usage
        args  = [self.input.key_vault_id.value]
      }

    }

  }

  container {
    width = 12

    table {
      title = "Access Policies"
      query = query.key_vault_access_policies
      args  = [self.input.key_vault_id.value]
    }

  }

  container {
    width = 12

    table {
      title = "Network Access Details"
      query = query.key_vault_network_acls
      args  = [self.input.key_vault_id.value]
    }

  }

}

query "key_vault_input" {
  sql = <<-EOQ
    select
      v.title as label,
      lower(v.id) as value,
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

# card queries

query "key_vault_purge_protection_status" {
  sql = <<-EOQ
    select
      'Purge Protection' as label,
      case when purge_protection_enabled then 'Enabled' else 'Disabled' end as value,
      case when purge_protection_enabled then 'ok' else 'alert' end as type
    from
      azure_key_vault
    where
      lower(id) = $1;
  EOQ
}

query "key_vault_public_network_access_enabled" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when network_acls is null or network_acls ->> 'defaultAction' != 'Deny' then 'Enabled' else 'Disabled' end as value,
      case when network_acls is null or network_acls ->> 'defaultAction' != 'Deny' then 'alert' else 'ok' end as type
    from
      azure_key_vault
    where
      lower(id) = $1;
  EOQ
}

query "key_vault_soft_delete_status" {
  sql = <<-EOQ
    select
      'Soft Delete' as label,
      case when soft_delete_enabled then 'Enabled' else 'Disabled' end as value,
      case when soft_delete_enabled then 'ok' else 'alert' end as type
    from
      azure_key_vault
    where
      lower(id) = $1;
  EOQ
}

query "key_vault_soft_delete_retention_in_days" {
  sql = <<-EOQ
    select
      'Soft Delete Retention Days' as label,
      soft_delete_retention_in_days as value
    from
      azure_key_vault
    where
      lower(id) = $1;
  EOQ
}

# with queries
query "key_vault_keys_for_key_vault" {
  sql = <<-EOQ
    select
      lower(k.id) as key_id
    from
      azure_key_vault_key as k
      left join azure_key_vault as v on v.name = k.vault_name
    where
      lower(v.id) = $1;
  EOQ
}

query "network_subnets_for_key_vault" {
  sql = <<-EOQ
    select
      lower(s.id) as subnet_id
    from
      azure_key_vault as v,
      jsonb_array_elements(network_acls -> 'virtualNetworkRules') as r
      left join azure_subnet as s on lower(s.id) = lower(r ->> 'id')
    where
      lower(v.id) = $1;
  EOQ
}

query "network_virtual_networks_for_key_vault" {
  sql = <<-EOQ
    with subnet as (
      select
        lower(s.id) as id
      from
        azure_key_vault as v,
        jsonb_array_elements(network_acls -> 'virtualNetworkRules') as r
        left join azure_subnet as s on lower(s.id) = lower(r ->> 'id')
      where
        lower(v.id) = $1
    )
    select
      lower(n.id) as virtual_network_id
    from
      azure_virtual_network as n,
      jsonb_array_elements(subnets) as s
    where
      lower(s ->> 'id') in (select id from subnet)
  EOQ
}

# table queries

query "key_vault_overview" {
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
      lower(id) = $1
  EOQ
}

query "key_vault_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_key_vault,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
  EOQ
}

query "key_vault_access_policies" {
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
      lower(id) = $1;
  EOQ
}

query "key_vault_sku" {
  sql = <<-EOQ
    select
      sku_family as "SKU Family",
      sku_name as "SKU Name"
    from
      azure_key_vault
    where
      lower(id) = $1;
  EOQ
}

query "key_vault_network_acls" {
  sql = <<-EOQ
    select
      network_acls ->> 'bypass' as "Bypass",
      network_acls ->> 'defaultAction' as "Default Action",
      network_acls ->> 'ipRules' as "IP Rules",
      network_acls ->> 'virtualNetworkRules' as "Virtual Network Rules"
    from
      azure_key_vault
    where
      lower(id) = $1;
  EOQ
}

query "key_vault_usage" {
  sql = <<-EOQ
    select
      enabled_for_deployment as "Enabled For Deployment",
      enabled_for_disk_encryption as "Enabled For Disk Encryption",
      enabled_for_template_deployment as "Enabled For Template Deployment"
    from
      azure_key_vault
    where
      lower(id) = $1;
  EOQ
}
