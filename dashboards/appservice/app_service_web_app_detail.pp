dashboard "app_service_web_app_detail" {

  title         = "Azure App Service Web App Detail"
  documentation = file("./dashboards/appservice/docs/app_service_web_app_detail.md")

  tags = merge(local.app_service_common_tags, {
    type = "Detail"
  })

  input "web_app_id" {
    title = "Select a web app:"
    query = query.app_service_web_app_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.app_service_web_app_state
      args  = [self.input.web_app_id.value]
    }

    card {
      width = 2
      query = query.app_service_web_app_kind
      args  = [self.input.web_app_id.value]
    }

    card {
      width = 2
      query = query.app_service_web_app_ftps_state
      args  = [self.input.web_app_id.value]
    }

    card {
      width = 2
      query = query.app_service_web_app_https
      args  = [self.input.web_app_id.value]
    }

    card {
      width = 2
      query = query.app_service_web_app_http_logging
      args  = [self.input.web_app_id.value]
    }

    card {
      width = 2
      query = query.app_service_web_app_tls_version
      args  = [self.input.web_app_id.value]
    }

  }

  with "network_application_gateways_for_app_service_web" {
    query = query.network_application_gateways_for_app_service_web
    args  = [self.input.web_app_id.value]
  }

  with "network_subnets_for_app_service_web" {
    query = query.network_subnets_for_app_service_web
    args  = [self.input.web_app_id.value]
  }

  with "network_virtual_networks_for_app_service_web" {
    query = query.network_virtual_networks_for_app_service_web
    args = [self.input.web_app_id.value]
  }

  container {
    graph {

      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.app_service_plan
        args = {
          app_service_web_app_ids = [self.input.web_app_id.value]
        }
      }

      node {
        base = node.app_service_web_app
        args = {
          app_service_web_app_ids = [self.input.web_app_id.value]
        }
      }

      node {
        base = node.network_application_gateway
        args = {
          network_application_gateway_ids = with.network_application_gateways_for_app_service_web.rows[*].application_gateway_id
        }
      }

      node {
        base = node.network_subnet
        args = {
          network_subnet_ids = with.network_subnets_for_app_service_web.rows[*].subnet_id
        }
      }

      node {
        base = node.network_virtual_network
        args = {
          network_virtual_network_ids = with.network_virtual_networks_for_app_service_web.rows[*].virtual_network_id
        }
      }

      edge {
        base = edge.app_service_web_app_to_app_service_plan
        args = {
          app_service_web_app_ids = [self.input.web_app_id.value]
        }
      }

      edge {
        base = edge.app_service_web_app_to_network_subnet
        args = {
          app_service_web_app_ids = [self.input.web_app_id.value]
        }
      }

      edge {
        base = edge.network_application_gateway_to_app_service_web_app
        args = {
          network_application_gateway_ids = with.network_application_gateways_for_app_service_web.rows[*].application_gateway_id
        }
      }

      edge {
        base = edge.network_subnet_to_network_virtual_network
        args = {
          network_subnet_ids = with.network_subnets_for_app_service_web.rows[*].subnet_id
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
        query = query.app_service_web_app_overview
        args  = [self.input.web_app_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.app_service_web_app_tags
        args  = [self.input.web_app_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "IP Security Restrictions"
        query = query.app_service_web_app_ip_security_restrictions
        args  = [self.input.web_app_id.value]
      }

    }
  }

  container {
      width = 12

      table {
        title = "Diagnostic Configuration"
        query = query.app_service_web_app_diagnostic_logs_configuration
        args  = [self.input.web_app_id.value]
      }

      table {
        title = "Site Configuration"
        query = query.app_service_web_app_configuration
        args  = [self.input.web_app_id.value]
      }

    }

  }

  query "app_service_web_app_input" {
    sql = <<-EOQ
      select
        wa.title as label,
        lower(wa.id) as value,
        json_build_object(
          'subscription', s.display_name,
          'resource_group', wa.resource_group,
          'region', wa.region
        ) as tags
      from
        azure_app_service_web_app as wa,
        azure_subscription as s
      where
        lower(wa.subscription_id) = lower(s.subscription_id)
      order by
        wa.title;
    EOQ
  }

  # Card Queries

  query "app_service_web_app_state" {
    sql = <<-EOQ
      select
        'State' as label,
        state as value
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ

  }

  query "app_service_web_app_kind" {
    sql = <<-EOQ
      select
        'Kind' as label,
        kind as value
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }

  query "app_service_web_app_ftps_state" {
    sql = <<-EOQ
      select
        'FTP' as label,
        configuration -> 'properties' ->> 'ftpsState' as value,
        case when configuration -> 'properties' ->> 'ftpsState' = 'AllAllowed' then 'alert' else 'ok' end as type
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }

  query "app_service_web_app_https" {
    sql = <<-EOQ
      select
        'HTTPS' as label,
        case when https_only then 'Enabled' else 'Disabled' end as value,
        case when https_only then 'ok' else 'alert' end as type
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }

  query "app_service_web_app_http_logging" {
    sql = <<-EOQ
      select
        'HTTP Logging' as label,
        case when (configuration -> 'properties' -> 'httpLoggingEnabled')::boolean then 'Enabled' else 'Disabled' end as value,
        case when (configuration -> 'properties' -> 'httpLoggingEnabled')::boolean then 'ok' else 'alert' end as type
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }

  query "app_service_web_app_tls_version" {
    sql = <<-EOQ
      select
        'TLS Version' as label,
        configuration -> 'properties' ->> 'minTlsVersion' as value,
        case when (configuration -> 'properties' ->> 'minTlsVersion')::decimal >= 1.2 then 'ok' else 'alert' end as type
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }

  # With Queries

  query "network_application_gateways_for_app_service_web" {
    sql = <<-EOQ
      with application_gateway as (
        select
          g.id as id,
          backend_address ->> 'fqdn' as app_host_name
        from
          azure_application_gateway as g,
          jsonb_array_elements(backend_address_pools) as pool,
          jsonb_array_elements(pool -> 'properties' -> 'backendAddresses') as backend_address
      )
      select
        lower(g.id) as application_gateway_id
      from
        azure_app_service_web_app as a,
        jsonb_array_elements(a.host_names) as host_name,
        application_gateway as g
      where
        lower(g.app_host_name) = lower(trim((host_name::text), '""'))
        and lower(a.id) = $1;
    EOQ
  }

  query "network_subnets_for_app_service_web" {
    sql = <<-EOQ
      select
        lower(id) as subnet_id
      from
        azure_subnet
      where
        lower(id) in (
          select
            lower(vnet_connection -> 'properties' ->> 'vnetResourceId')
          from
            azure_app_service_web_app
          where
            lower(id) = $1
        );
    EOQ
  }

  query "network_virtual_networks_for_app_service_web" {
    sql = <<-EOQ
      select
        lower(id) as virtual_network_id
      from
        azure_virtual_network,
          jsonb_array_elements(subnets) as sub
      where
        lower(sub ->> 'id') in (
          select
            lower(vnet_connection -> 'properties' ->> 'vnetResourceId')
          from
            azure_app_service_web_app
          where
            lower(id) = $1
        );
    EOQ
  }

  # Table Queries

  query "app_service_web_app_overview" {
    sql = <<-EOQ
      select
        name as "Name",
        default_site_hostname as "Default Site Hostname",
        cloud_environment as "Cloud Environment",
        case when enabled::boolean then 'Online' else 'Offline' end as "Status",
        type as "Type",
        region as "Region",
        resource_group as "Resource Group",
        subscription_id as "Subscription ID",
        id as "ID"
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }

  query "app_service_web_app_tags" {
    sql = <<-EOQ
      select
        tag.key as "Key",
        tag.value as "Value"
      from
        azure_app_service_web_app,
        jsonb_each_text(tags) as tag
      where
        lower(id) = $1
      order by
        tag.key;
    EOQ
  }

  query "app_service_web_app_ip_security_restrictions" {
    sql = <<-EOQ
      select
        r ->> 'name' as "Name",
        r ->> 'priority' as "Priority",
        r ->> 'ipAddress' as "IP Address",
        r ->> 'action' as "Action",
        r ->> 'description' as "Description"
      from
        azure_app_service_web_app,
        jsonb_array_elements(configuration -> 'properties' -> 'ipSecurityRestrictions') as r
      where
        lower(id) = $1;
    EOQ
  }

  query "app_service_web_app_diagnostic_logs_configuration" {
    sql = <<-EOQ
      select
        diagnostic_logs_configuration -> 'properties' -> 'applicationLogs' -> 'azureBlobStorage' ->> 'level' as "Application logging (Blob)",
        diagnostic_logs_configuration -> 'properties' -> 'applicationLogs' -> 'azureTableStorage' ->> 'level' as "Application logging (Table)",
        diagnostic_logs_configuration -> 'properties' -> 'applicationLogs' -> 'fileSystem' ->> 'level' as "Application logging (Filesystem)",
        case when (diagnostic_logs_configuration -> 'properties' -> 'detailedErrorMessages' -> 'enabled')::boolean then 'Enabled' else 'Disabled' end as "Detailed Error Messages",
        case when (diagnostic_logs_configuration -> 'properties' -> 'failedRequestsTracing' -> 'enabled')::boolean then 'Enabled' else 'Disabled' end as "Failed Requests Tracing",
        case when (diagnostic_logs_configuration -> 'properties' -> 'httpLogs' -> 'azureBlobStorage' -> 'enabled')::boolean then 'Enabled' else 'Disabled' end as "Web server logging (Storage)",
        case when (diagnostic_logs_configuration -> 'properties' -> 'httpLogs' -> 'fileSystem' -> 'enabled')::boolean then 'Enabled' else 'Disabled' end as "Web server logging (Filesystem)"
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }

  query "app_service_web_app_configuration" {
    sql = <<-EOQ
      select
        configuration -> 'properties' ->> 'loadBalancing' as "Load Balancing",
        configuration -> 'properties' ->> 'linuxFxVersion' as "Linux App Framework and version",
        configuration -> 'properties' ->> 'numberOfWorkers' as "Workers",
        configuration -> 'properties' ->> 'preWarmedInstanceCount' as "Pre-warmed Instances",
        case when (configuration -> 'properties' ->> 'alwaysOn')::boolean then 'Enabled' else 'Disabled' end as "Always On",
        case when (configuration -> 'properties' ->> 'autoHealEnabled')::boolean then 'Enabled' else 'Disabled' end as "Auto Heal",
        case when (configuration -> 'properties' ->> 'detailedErrorLoggingEnabled')::boolean then 'Enabled' else 'Disabled' end as "Detailed Error Logging",
        case when (configuration -> 'properties' ->> 'http20Enabled')::boolean then 'Enabled' else 'Disabled' end as "HTTP 20",
        case when (configuration -> 'properties' ->> 'httpLoggingEnabled')::boolean then 'Enabled' else 'Disabled' end as "HTTP Logging",
        case when (configuration -> 'properties' ->> 'localMySqlEnabled')::boolean then 'Enabled' else 'Disabled' end as "Local MySQL",
        configuration -> 'properties' ->> 'logsDirectorySizeLimit' as "HTTP Logs Directory Size Limit",
        configuration -> 'properties' ->> 'managedPipelineMode' as "Managed Pipeline Mode",
        case when (configuration -> 'properties' ->> 'remoteDebuggingEnabled')::boolean then 'Enabled' else 'Disabled' end as "Remote Debugging",
        case when (configuration -> 'properties' ->> 'requestTracingEnabled')::boolean then 'Enabled' else 'Disabled' end as "Request Tracing"
      from
        azure_app_service_web_app
      where
        lower(id) = $1;
    EOQ
  }
