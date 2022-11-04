dashboard "azure_app_service_web_app_dashboard" {

  title         = "Azure App Service Web App Dashboard"
  documentation = file("./dashboards/compute/docs/compute_disk_dashboard.md")

  tags = merge(local.app_service_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.azure_app_service_web_app_count
      width = 2
    }

    card {
      query = query.azure_app_service_web_app_offline_count
      width = 2
    }

    card {
      query = query.azure_app_service_web_app_https_disabled_count
      width = 2
    }

    card {
      query = query.azure_app_service_web_app_http_logging_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Online/Offline"
      query = query.azure_app_service_web_app_by_status
      type  = "donut"
      width = 2

      series "count" {
        point "Online" {
          color = "ok"
        }
        point "Offline" {
          color = "alert"
        }
      }
    }

    chart {
      title = "HTTPS Status"
      query = query.azure_app_service_web_app_by_network_traffic_protocol
      type  = "donut"
      width = 2

      series "count" {
        point "HTTPS" {
          color = "ok"
        }
        point "HTTP" {
          color = "alert"
        }
      }
    }

    chart {
      title = "HTTP Logging Status"
      query = query.azure_app_service_web_app_by_http_logging
      type  = "donut"
      width = 2

      series "count" {
        point "Enabled" {
          color = "ok"
        }
        point "Disabled" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Web Apps by Subscription"
      query = query.azure_app_service_web_app_by_subscription
      type  = "column"
      width = 4
    }

    chart {
      title = "Web Apps by Resource Group"
      query = query.azure_app_service_web_app_by_resource_group
      type  = "column"
      width = 4
    }

    chart {
      title = "Web Apps by Region"
      query = query.azure_app_service_web_app_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Web Apps by Kind"
      query = query.azure_app_service_web_app_by_kind
      type  = "column"
      width = 4
    }

    chart {
      title = "Web Apps by State"
      query = query.azure_app_service_web_app_by_state
      type  = "column"
      width = 4
    }

    chart {
      title = "Web Apps by FTP State"
      query = query.azure_app_service_web_app_by_ftp_state
      type  = "column"
      width = 4
    }
  }

}

# Card Queries

query "azure_app_service_web_app_count" {
  sql = <<-EOQ
    select count(*) as "Web Apps" from azure_app_service_web_app;
  EOQ
}

query "azure_app_service_web_app_offline_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'Offline' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_app_service_web_app
    where
      not enabled;
  EOQ
}

query "azure_app_service_web_app_https_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'HTTPS Disabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_app_service_web_app
    where
      not https_only;
  EOQ
}

query "azure_app_service_web_app_http_logging_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'HTTP Logging Disabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_app_service_web_app
    where
      not (configuration -> 'properties' ->> 'httpLoggingEnabled')::boolean;
  EOQ
}

# Assessment Queries

query "azure_app_service_web_app_by_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select
        case when enabled::boolean then 'Online' else 'Offline' end as status
      from
        azure_app_service_web_app
    ) as wa
    group by
      status
    order by
      status;
  EOQ
}

query "azure_app_service_web_app_by_network_traffic_protocol" {
  sql = <<-EOQ
    select
      protocol,
      count(*)
    from (
      select
        case when https_only::boolean then 'HTTPS' else 'HTTP' end as protocol
      from
        azure_app_service_web_app
    ) as wa
    group by
      protocol
    order by
      protocol;
  EOQ
}

query "azure_app_service_web_app_by_http_logging" {
  sql = <<-EOQ
    select
      http_logging,
      count(*)
    from (
      select
        case when (configuration -> 'properties' ->> 'httpLoggingEnabled')::boolean then 'Enabled' else 'Disabled' end as http_logging
      from
        azure_app_service_web_app
    ) as wa
    group by
      http_logging
    order by
      http_logging;
  EOQ
}

# Analysis Queries

query "azure_app_service_web_app_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(wa.*) as "Web Apps"
    from
      azure_app_service_web_app as wa,
      azure_subscription as sub
    where
      sub.subscription_id = wa.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "azure_app_service_web_app_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(wa.*) as "Web Apps"
    from
      azure_app_service_web_app as wa,
      azure_subscription as sub
    where
      wa.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_app_service_web_app_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Web Apps"
    from
      azure_app_service_web_app
    group by
      region
    order by
      region;
  EOQ
}

query "azure_app_service_web_app_by_kind" {
  sql = <<-EOQ
    select
      kind as "App Kind",
      count(kind) as "Web Apps"
    from
      azure_app_service_web_app
    group by
      kind
    order by
      kind;
  EOQ
}

query "azure_app_service_web_app_by_state" {
  sql = <<-EOQ
    select
      state as "State",
      count(id) as "Web Apps"
    from
      azure_app_service_web_app
    group by
      state
    order by
      state;
  EOQ
}

query "azure_app_service_web_app_by_ftp_state" {
  sql = <<-EOQ
    select
      configuration -> 'properties' ->> 'ftpsState' as "FTP State",
      count(id) as "Web Apps"
    from
      azure_app_service_web_app
    group by
      configuration -> 'properties' ->> 'ftpsState'
    order by
      configuration -> 'properties' ->> 'ftpsState';
  EOQ
}
