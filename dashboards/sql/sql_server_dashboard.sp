dashboard "azure_sql_server_dashboard" {

  title = "Azure SQL Server Dashboard"

  tags = merge(local.sql_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.azure_sql_server_count.sql
      width = 2
    }

    card {
      sql   = query.azure_sql_server_public_count.sql
      width = 2
    }

    card {
      sql   = query.azure_sql_server_auditing_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_sql_server_vulnerability_assessment_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_sql_server_azure_ad_authentication_disabled_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Public/Private Status"
      sql   = query.azure_sql_server_public_status.sql
      type  = "donut"
      width = 2

      series "count" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Auditing Status"
      sql   = query.azure_sql_server_auditing_status.sql
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
      title = "Vulnerability Assessment Status"
      sql   = query.azure_sql_server_vulnerability_assessment_status.sql
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
      title = "Azure AD Authentication Status"
      sql   = query.azure_sql_server_ad_authentication_status.sql
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
      title = "Private Link Status"
      sql   = query.azure_sql_server_private_link_status.sql
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
      title = "Servers by Subscription"
      sql   = query.azure_sql_server_by_subscription.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Servers by Resource Group"
      sql   = query.azure_sql_server_by_resource_group.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Servers by Region"
      sql   = query.azure_sql_server_by_region.sql
      type  = "column"
      width = 3
    }

     chart {
      title = "Servers by Encryption Type"
      sql   = query.azure_sql_server_by_encryption_type.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Servers by Kind"
      sql   = query.azure_sql_server_by_kind.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Servers by State"
      sql   = query.azure_sql_server_by_state.sql
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "azure_sql_server_count" {
  sql = <<-EOQ
    select count(*) as "Servers" from azure_sql_server;
  EOQ
}

query "azure_sql_server_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_sql_server
    where
      public_network_access = 'Enabled';
  EOQ
}

query "azure_sql_server_vulnerability_assessment_disabled_count" {
  sql = <<-EOQ
    with sql_server_va as (
      select
        distinct id
      from
        azure_sql_server as s,
        jsonb_array_elements(server_vulnerability_assessment) as va
      where
        va -> 'properties' -> 'recurringScans' ->> 'isEnabled' = 'true'
    )
    select
      count(*) as value,
      'Vulnerability Assessment Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
     azure_sql_server where id not in (select id from sql_server_va);
  EOQ
}

query "azure_sql_server_auditing_disabled_count" {
  sql = <<-EOQ
    with sql_server_audit_enabled as (
      select
        distinct id
      from
        azure_sql_server as s,
        jsonb_array_elements(server_audit_policy) as audit
      where
        audit -> 'properties' ->> 'state' = 'Enabled'
    )
    select
      count(*) as value,
      'Auditing Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
     azure_sql_server where id not in (select id from sql_server_audit_enabled);
  EOQ
}

query "azure_sql_server_azure_ad_authentication_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Azure AD Authentication Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
     azure_sql_server
    where
    server_azure_ad_administrator is null;
  EOQ
}

# Assessment Queries

query "azure_sql_server_public_status" {
  sql = <<-EOQ
    select
      public_network,
      count(*)
    from (
      select
        case when public_network_access = 'Enabled' then 'public'
        else 'private'
        end public_network
      from
        azure_sql_server) as s
    group by
      public_network
    order by
      public_network;
  EOQ
}

query "azure_sql_server_vulnerability_assessment_status" {
  sql = <<-EOQ
   with vulnerability_assessment_enabled as (
      select
        distinct id
      from
        azure_sql_server as s,
        jsonb_array_elements(server_vulnerability_assessment) as va
      where
        va -> 'properties' -> 'recurringScans' ->> 'isEnabled' = 'true'
    ),
    vulnerability_assessment_status as (
      select
        case
          when s.name is not null  then 'enabled'
          else 'disabled' end as vulnerability_assessment_status
      from
        azure_sql_server as s
        left join vulnerability_assessment_enabled as va on s.id = va.id
    )
    select
      vulnerability_assessment_status,
      count(*)
    from
      vulnerability_assessment_status
    group by
      vulnerability_assessment_status;
  EOQ
}

query "azure_sql_server_auditing_status" {
  sql = <<-EOQ
   with auditing_enabled as (
      select
        distinct id
      from
        azure_sql_server as s,
        jsonb_array_elements(server_audit_policy) as audit
      where
        audit -> 'properties' ->> 'state' = 'Enabled'
    ),
    auditing_enabled_status as (
      select
        case
          when s.name is not null  then 'enabled'
          else 'disabled' end as auditing_enabled_status
      from
        azure_sql_server as s
        left join auditing_enabled as va on s.id = va.id
    )
    select
      auditing_enabled_status,
      count(*)
    from
      auditing_enabled_status
    group by
      auditing_enabled_status;
  EOQ
}

query "azure_sql_server_ad_authentication_status" {
  sql = <<-EOQ
    select
      ad_authentication,
      count(*)
    from (
      select
        case when server_azure_ad_administrator is null then 'disabled'
        else 'enabled'
        end ad_authentication
      from
        azure_sql_server) as s
    group by
      ad_authentication
    order by
      ad_authentication;
  EOQ
}

query "azure_sql_server_private_link_status" {
  sql = <<-EOQ
    with private_link_enabled as (
      select
        distinct s.id
      from
        azure_sql_server as s,
        jsonb_array_elements(private_endpoint_connections) as connection
      where
        connection ->> 'PrivateLinkServiceConnectionStateStatus' = 'Approved'
    ),
    private_link_status as (
      select
        case
          when va.id is not null then 'enabled'
          else 'disabled' end as private_link_enabled
      from
        azure_sql_server as s
        left join private_link_enabled as va on s.id = va.id
    )
    select
      private_link_enabled,
      count(*)
    from
      private_link_status
    group by
      private_link_enabled;
  EOQ
}

# Analysis Queries

query "azure_sql_server_by_subscription" {
  sql = <<-EOQ
    select
      a.title as "Subscription",
      count(v.*) as "Servers"
    from
      azure_sql_server as v,
      azure_subscription as a
    where
      a.subscription_id = v.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "azure_sql_server_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(resource_group) as "Accounts"
    from
      azure_sql_server as v,
      azure_subscription as sub
    where
       v.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_sql_server_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Servers"
    from
      azure_sql_server
    group by
      region
    order by
      region;
  EOQ
}

query "azure_sql_server_by_encryption_type" {
  sql = <<-EOQ
    with encryption_type as (
      select
        id,
        ep  -> 'serverKeyType' as serverKeyType
      from
        azure_sql_server as s,
        jsonb_array_elements(encryption_protector) as ep
    )
    select
      serverKeyType as "serverKeyType",
      count(serverKeyType) as "Servers"
    from
      encryption_type
    group by
      serverKeyType
    order by
      serverKeyType;
  EOQ
}

query "azure_sql_server_by_kind" {
  sql = <<-EOQ
    select
      kind as "Kind",
      count(kind) as "Servers"
    from
      azure_sql_server
    group by
      kind
    order by
      kind;
  EOQ
}

query "azure_sql_server_by_state" {
  sql = <<-EOQ
    select
      state as "State",
      count(kind) as "Servers"
    from
      azure_sql_server
    group by
      state
    order by
      state;
  EOQ
}

query "azure_sql_server_default_encrypted_servers_count" {
  sql = <<-EOQ
    select
      count(*) as "Service-Managed Encryption"
    from
      azure_sql_server as s,
      jsonb_array_elements(encryption_protector) as ep
    where
      ep ->> 'serverKeyType' = 'ServiceManaged'
  EOQ
}

query "azure_sql_server_customer_managed_encryption_count" {
  sql = <<-EOQ
   select
      count(*) as "Customer-Managed Encryption"
    from
      azure_sql_server as s,
      jsonb_array_elements(encryption_protector) as ep
    where
      ep ->> 'serverKeyType' <> 'ServiceManaged'
  EOQ
}