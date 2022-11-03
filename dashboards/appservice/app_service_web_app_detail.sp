dashboard "azure_app_service_web_app_detail" {

  title         = "Azure App Service Web App Detail"
  documentation = file("./dashboards/keyvault/docs/key_vault_detail.md")

  tags = merge(local.app_service_common_tags, {
    type = "Detail"
  })

  input "web_app_id" {
    title = "Select a web app:"
    query = query.azure_app_service_web_app_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_app_service_web_app_state
      args = {
        id = self.input.web_app_id.value
      }
    }

    card {
      width = 2
      query = query.azure_app_service_web_app_kind
      args = {
        id = self.input.web_app_id.value
      }
    }

    card {
      width = 2
      query = query.azure_app_service_web_app_ftps_state
      args = {
        id = self.input.web_app_id.value
      }
    }

    card {
      width = 2
      query = query.azure_app_service_web_app_https
      args = {
        id = self.input.web_app_id.value
      }
    }

    card {
      width = 2
      query = query.azure_app_service_web_app_http_logging
      args = {
        id = self.input.web_app_id.value
      }
    }

    card {
      width = 2
      query = query.azure_app_service_web_app_tls_version
      args = {
        id = self.input.web_app_id.value
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
        query = query.azure_app_service_web_app_overview
        args = {
          id = self.input.web_app_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_app_service_web_app_tags
        args = {
          id = self.input.web_app_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "IP Security Restrictions"
        query = query.azure_app_service_web_app_ip_security_restrictions
        args = {
          id = self.input.web_app_id.value
        }
      }

      # table {
      #   title = "Outbound IP Addresses"
      #   query = query.azure_app_service_web_app_outbound_ip_addresses
      #   args = {
      #     id = self.input.web_app_id.value
      #   }
      # }

    }

    container {
      width = 12

      table {
        title = "Diagnostic Configuration"
        query = query.azure_app_service_web_app_diagnostic_logs_configuration
        args = {
          id = self.input.web_app_id.value
        }
      }

      table {
        title = "Site Configuration"
        query = query.azure_app_service_web_app_configuration
        args = {
          id = self.input.web_app_id.value
        }
      }

    }

  }
}

query "azure_app_service_web_app_input" {
  sql = <<-EOQ
    select
      wa.title as label,
      wa.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', wa.resource_group,
        'region', wa.region
      ) as tags
    from
      azure_app_service_web_app as wa,
      azure_subscription as s
    where
      wa.subscription_id = s.subscription_id
    order by
      wa.title;
  EOQ
}

query "azure_app_service_web_app_state" {
  sql = <<-EOQ
    select
      'State' as label,
      state as value
    from
      azure_app_service_web_app
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_kind" {
  sql = <<-EOQ
    select
      'Kind' as label,
      kind as value
    from
      azure_app_service_web_app
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_ftps_state" {
  sql = <<-EOQ
    select
      'FTP State' as label,
      configuration -> 'properties' ->> 'ftpsState' as value
    from
      azure_app_service_web_app
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_https" {
  sql = <<-EOQ
    select
      'HTTPS' as label,
      case when https_only then 'Enabled' else 'Disabled' end as value,
      case when https_only then 'ok' else 'alert' end as type
    from
      azure_app_service_web_app
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_http_logging" {
  sql = <<-EOQ
    select
      'HTTP Logging' as label,
      case when (configuration -> 'properties' -> 'httpLoggingEnabled')::boolean then 'Enabled' else 'Disabled' end as value,
      case when (configuration -> 'properties' -> 'httpLoggingEnabled')::boolean then 'ok' else 'alert' end as type
    from
      azure_app_service_web_app
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_tls_version" {
  sql = <<-EOQ
    select
      'TLS Version' as label,
      configuration -> 'properties' ->> 'minTlsVersion' as value,
      case when (configuration -> 'properties' ->> 'minTlsVersion')::decimal >= 1.2 then 'ok' else 'alert' end as type
    from
      azure_app_service_web_app
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_overview" {
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
      id = $1
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_app_service_web_app,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_app_service_web_app_ip_security_restrictions" {
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
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_outbound_ip_addresses" {
  sql = <<-EOQ
    select
      unnest(string_to_array(possible_outbound_ip_addresses,',')) as "Outbound IP Address"
    from
      azure_app_service_web_app
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_diagnostic_logs_configuration" {
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
      id = $1;
  EOQ

  param "id" {}
}

query "azure_app_service_web_app_configuration" {
  sql = <<-EOQ
    select
      configuration -> 'properties' ->> 'linuxFxVersion' as "Linux App Framework and version",
      configuration -> 'properties' ->> 'loadBalancing' as "Load Balancing",
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
      id = $1;
  EOQ
  param "id" {}
}
