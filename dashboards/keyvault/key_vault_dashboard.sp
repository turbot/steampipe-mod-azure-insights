dashboard "key_vault_dashboard" {

  title         = "Azure Key Vault Dashboard"
  documentation = file("./dashboards/keyvault/docs/key_vault_dashboard.md")

  tags = merge(local.keyvault_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.key_vault_count
      width = 2
    }

    card {
      query = query.key_vault_purge_protection_enabled_count
      width = 2
    }

    card {
      query = query.key_vault_soft_delete_enabled_count
      width = 2
    }

    card {
      query = query.key_vault_public_network_access_enabled_count
      width = 2
    }
  }

  container {
    title = "Assessments"

    chart {
      title = "Purge Protection Status"
      query = query.key_vault_by_purge_protection_status
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
      title = "Soft-Delete Status"
      query = query.key_vault_by_soft_delete_status
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
      title = "Public Network Access Status"
      query = query.key_vault_by_public_network_access_status
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

  }

  container {
    title = "Analysis"

    chart {
      title = "Vaults by Subscription"
      query = query.key_vault_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Vaults by Resource Group"
      query = query.key_vault_by_resource_group
      type  = "column"
      width = 3
    }

    chart {
      title = "Vaults by Region"
      query = query.key_vault_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Vaults by SKU"
      query = query.key_vault_by_sku
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "key_vault_count" {
  sql = <<-EOQ
    select count(*) as "Vaults" from azure_key_vault;
  EOQ
}

query "key_vault_purge_protection_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Purge Protection Disabled' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      azure_key_vault
    where
      not purge_protection_enabled;
  EOQ
}

query "key_vault_soft_delete_enabled_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      'Soft-Delete Disabled' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      azure_key_vault
    where
      not soft_delete_enabled;
  EOQ
}

query "key_vault_public_network_access_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Access Enabled' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      azure_key_vault
    where
      network_acls is null or network_acls ->> 'defaultAction' != 'Deny';
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

query "key_vault_by_purge_protection_status" {
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

query "key_vault_by_soft_delete_status" {
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

query "key_vault_by_public_network_access_status" {
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

# Analysis Queries

query "key_vault_by_subscription" {
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

query "key_vault_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(v.*) as "Vaults"
    from
      azure_key_vault as v,
      azure_subscription as sub
    where
       v.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "key_vault_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Vaults" from azure_key_vault group by region order by region;
  EOQ
}

query "key_vault_by_sku" {
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
