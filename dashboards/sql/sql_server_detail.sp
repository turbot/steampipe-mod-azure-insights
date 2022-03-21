dashboard "azure_sql_server_detail" {

  title         = "Azure SQL Server Detail"
  documentation = file("./dashboards/sql/docs/sql_server_detail.md")

  tags = merge(local.sql_common_tags, {
    type = "Detail"
  })

  input "server_id" {
    title = "Select a server:"
    query = query.azure_sql_server_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_sql_server_state
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_version
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_kind
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_public_network_access
      args = {
        id = self.input.server_id.value
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
        query = query.azure_sql_server_overview
        args = {
          id = self.input.server_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_sql_server_tags
        args = {
          id = self.input.server_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Administrator Details"
        query = query.azure_sql_server_administrator
        args = {
          id = self.input.server_id.value
        }
      }

      table {
        title = "Encryption"
        query = query.azure_sql_server_encryption
        args = {
          id = self.input.server_id.value
        }
      }

    }
  }

  container {
    width = 12

    table {
      title = "Virtual Network Rules"
      query = query.azure_sql_server_virtual_network_rules
      args = {
        id = self.input.server_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Audit Policy"
      query = query.azure_sql_server_audit_policy
      args = {
        id = self.input.server_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Vulnerability Assessment"
      query = query.azure_sql_server_vulnerability_assessment
      args = {
        id = self.input.server_id.value
      }
    }

  }

}

query "azure_sql_server_input" {
  sql = <<-EOQ
    select
      s.title as label,
      s.id as value,
      json_build_object(
        'subscription', sub.display_name,
        'resource_group', s.resource_group,
        'region', s.region
      ) as tags
    from
      azure_sql_server as s,
      azure_subscription as sub
    where
      s.subscription_id = s.subscription_id
    order by
      s.title;
  EOQ
}

query "azure_sql_server_state" {
  sql = <<-EOQ
    select
      'State' as label,
      state as value
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_sql_server_version" {
  sql = <<-EOQ
    select
      'Version' as label,
      version as value
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_kind" {
  sql = <<-EOQ
    select
      'Kind' as label,
      kind as value
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_public_network_access" {
  sql = <<-EOQ
    select
      'Public Network Access' as label,
      case when public_network_access = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when public_network_access = 'Enabled' then 'alert' else 'ok' end as type
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      fully_qualified_domain_name as "Fully Qualified Domain Name",
      minimal_tls_version as "Minimal TLS Version",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_sql_server
    where
      id = $1
  EOQ

  param "id" {}
}

query "azure_sql_server_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_sql_server,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_sql_server_administrator" {
  sql = <<-EOQ
    select
      administrator_login as "Administrator Login",
      administrator_login_password as "Administrator Login Password"
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_encryption" {
  sql = <<-EOQ
    select
      ep ->> 'id' as "ID",
      ep ->> 'kind' as "Kind",
      ep ->> 'name' as "Name",
      ep ->> 'serverKeyName' as "Server Key Name",
      ep ->> 'serverKeyType' as "Server Key Type",
      ep ->> 'type' as "Type"
    from
      azure_sql_server,
      jsonb_array_elements(encryption_protector) as ep
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_virtual_network_rules" {
  sql = <<-EOQ
    select
      r ->> 'id' as "ID",
      r ->> 'name' as "Name",
      r -> 'properties' ->> 'ignoreMissingVnetServiceEndpoint' as "Ignore Missing Vnet Service Endpoint",
      r ->> 'virtualNetworkSubnetId' as "Virtual Network Subnet ID",
      r ->> type as "Type"
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as r
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_audit_policy" {
  sql = <<-EOQ
    select
      p ->> 'id' as "ID",
      p ->> 'name' as "Name",
      p -> 'properties' -> 'auditActionsAndGroups' as "Audit Actions And Groups",
      p ->> 'isAzureMonitorTargetEnabled' as "Is Azure Monitor Target Enabled",
      p ->> 'retentionDays' as "Retention Days",
      p ->> 'state' as "state",
      p ->> 'isStorageSecondaryKeyInUse' as "Is Storage Secondary Key In Use",
      p ->> 'storageAccountSubscriptionId' as "Storage Account Subscription ID",
      p ->> type as "Type"
    from
      azure_sql_server,
      jsonb_array_elements(server_audit_policy) as p
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_vulnerability_assessment" {
  sql = <<-EOQ
    select
      a ->> 'id' as "ID",
      a ->> 'name' as "Name",
      a -> 'properties' -> 'recurringScans' -> 'emailSubscriptionAdmins' as "Email Subscription Admins",
      a -> 'properties' -> 'recurringScans' -> 'isEnabled' as "Is Enabled",
      a -> 'type'  as "Type"
    from
      azure_sql_server,
      jsonb_array_elements(server_vulnerability_assessment) as a
    where
      id = $1;
  EOQ

  param "id" {}
}
