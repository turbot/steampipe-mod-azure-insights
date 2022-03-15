dashboard "azure_key_vault_dashboard" {

  title = "Azure Key Vault Dashboard"

  tags = merge(local.kms_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.azure_key_vault_count.sql
      width = 2
    }

    card {
      sql   = query.azure_key_vault_purge_protection_enabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_key_vault_soft_delete_enabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_key_vault_public_network_access_enabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_key_vault_virtual_service_endpoint_configured_count.sql
      width = 2
    }

    card {
      sql   = query.azure_key_vault_private_link_enabled_count.sql
      width = 2
    }
  }

  container {
    title = "Assessments"

    chart {
      title = "Purge Protection State"
      sql   = query.azure_key_vault_by_purge_protection_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Soft Delete State"
      sql   = query.azure_key_vault_by_soft_delete_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Public Network Access State"
      sql   = query.azure_key_vault_by_public_network_access_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "alert"
        }
        point "disabled" {
          color = "ok"
        }
      }
    }

    chart {
      title = "Virtual Service Endpoint"
      sql   = query.azure_key_vault_by_virtual_service_endpoint_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "configured" {
          color = "ok"
        }
        point "not configured" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Private Link"
      sql   = query.azure_key_vault_by_private_link_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Vaults by Subscription"
      sql   = query.azure_key_vault_by_subscription.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Vaults by Resource Group"
      sql   = query.azure_key_vault_by_resource_group.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Vaults by Region"
      sql   = query.azure_key_vault_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Vaults by SKU"
      sql   = query.azure_key_vault_by_sku.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "azure_key_vault_count" {
  sql = <<-EOQ
    select count(*) as "Vaults" from azure_key_vault;
  EOQ
}

query "azure_key_vault_purge_protection_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Purge Protection Enabled' as label,
      case when count(*) > 0 then 'ok' else 'alert' end as "type"
    from
      azure_key_vault
    where
      purge_protection_enabled;
  EOQ
}

query "azure_key_vault_soft_delete_enabled_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      'Soft Delete Enabled' as label,
      case when count(*) > 0 then 'ok' else 'alert' end as "type"
    from
      azure_key_vault
    where
      soft_delete_enabled;
  EOQ
}

query "azure_key_vault_public_network_access_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Network Access Enabled' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      azure_key_vault
    where
      network_acls is null or network_acls ->> 'defaultAction' != 'Deny';
  EOQ
}

query "azure_key_vault_virtual_service_endpoint_configured_count" {
  sql = <<-EOQ
    with keyvault_vault_subnet as (
      select
        distinct a.name,
        rule ->> 'id' as id
      from
        azure_key_vault as a,
        jsonb_array_elements(network_acls -> 'virtualNetworkRules') as rule
      where
        rule ->> 'id' is not null
    )
    select
      count(*) as value,
      'Virtual Service Endpoint Configured' as label,
      case when count(*) > 0 then 'ok' else 'alert' end as "type"
    from
      azure_key_vault as a
      left join keyvault_vault_subnet as s on a.name = s.name
    where
      network_acls ->> 'defaultAction' = 'Deny' and
      s.name is not null;
  EOQ
}

query "azure_key_vault_private_link_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Private Link Enabled' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      azure_key_vault
    where
      network_acls is null or
      network_acls ->> 'defaultAction' = 'Allow' and
      private_endpoint_connections is null;
  EOQ
}

# Assessment Queries

query "azure_key_vault_by_purge_protection_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select purge_protection_enabled,
        case when purge_protection_enabled then 'enabled'
        else 'disabled'
        end status
      from
        azure_key_vault) as kv
    group by
      status
    order by
      status;
  EOQ
}

query "azure_key_vault_by_soft_delete_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select soft_delete_enabled,
        case when soft_delete_enabled then 'enabled'
        else 'disabled'
        end status
      from
        azure_key_vault) as kv
    group by
      status
    order by
      status;
  EOQ
}

query "azure_key_vault_by_public_network_access_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select network_acls,
        case when network_acls is null or network_acls ->> 'defaultAction' != 'Deny' then 'enabled'
        else 'disabled'
        end status
      from
        azure_key_vault) as kv
    group by
      status
    order by
      status;
  EOQ
}

query "azure_key_vault_by_virtual_service_endpoint_status" {
  sql = <<-EOQ
    with keyvault_vault_subnet as (
      select
        distinct a.name,
        rule ->> 'id' as id
      from
        azure_key_vault as a,
        jsonb_array_elements(network_acls -> 'virtualNetworkRules') as rule
      where
        rule ->> 'id' is not null
    )
    select
      status,
      count(*)
    from (
      select network_acls,
        case when network_acls ->> 'defaultAction' <> 'Deny' or
          s.name is null then 'not configured'
        else 'configured'
        end status
      from
        azure_key_vault as a
        left join keyvault_vault_subnet as s on a.name = s.name) as kv
    group by
      status
    order by
      status;
  EOQ
}

query "azure_key_vault_by_private_link_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select network_acls,
        case when private_endpoint_connections @>  '[{"PrivateLinkServiceConnectionStateStatus": "Approved"}]'
        then 'enabled'
        else 'disabled'
        end status
      from
        azure_key_vault) as kv
    group by
      status
    order by
      status;
  EOQ
}

# Analysis Queries

query "azure_key_vault_by_subscription" {
  sql = <<-EOQ
    select
      a.title as "Subscription",
      count(v.*) as "Vaults"
    from
      azure_key_vault as v,
      azure_subscription as a
    where
      a.subscription_id = v.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "azure_key_vault_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group as "Resource Group",
      count(resource_group) as "Vaults"
    from
      azure_key_vault
    group by
      resource_group
    order by
      resource_group;
  EOQ
}

query "azure_key_vault_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Vaults" from azure_key_vault group by region order by region;
  EOQ
}

query "azure_key_vault_by_sku" {
  sql = <<-EOQ
    select
      sku_name as "SKU",
      count(sku_name) as "Vaults"
    from
      azure_key_vault
    group by
      sku_name
    order by
      sku_name;
  EOQ
}
