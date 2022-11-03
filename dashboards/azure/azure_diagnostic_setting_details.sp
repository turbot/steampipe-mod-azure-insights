dashboard "azure_diagnostic_setting_detail" {

  title         = "Azure Diagonostic Setting Detail"
  documentation = file("./dashboards/azure/docs/azure_diagnostic_setting_details.md")

  tags = merge(local.azure_common_tags, {
    type = "Detail"
  })

  input "id" {
    title = "Select a id:"
    query = query.azure_diagnostic_setting_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_diagnostic_setting_alert_log
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_diagnostic_setting_adiministrative_log
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_diagnostic_setting_security_log
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_diagnostic_recommendation_log
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_diagnostic_policy_log
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_diagnostic_autoscale_log
      args = {
        id = self.input.id.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_diagnostic_setting_node
      ]

      edges = [
        
      ]

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
        query = query.azure_diagnostic_setting_overview
        args = {
          id = self.input.id.value
        }

      }

    }
  }

}

query "azure_diagnostic_setting_input" {
  sql = <<-EOQ
    select
      ds.title as label,
      ds.id as value,
      json_build_object(
        'resource_group', ds.resource_group
      ) as tags
    from
      azure_diagnostic_setting as ds,
      azure_subscription as s
    where
      ds.subscription_id = s.subscription_id
    order by
      ds.title;
  EOQ
}

query "azure_diagnostic_setting_alert_log" {
  sql = <<-EOQ
    select
      'Alert Log' as label,
      case when  l ->> 'enabled' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when  l ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      azure_diagnostic_setting,
      jsonb_array_elements(logs) as l
    where
      l ->> 'category' = 'Alert'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_diagnostic_setting_adiministrative_log" {
  sql = <<-EOQ
    select
      'Administrative Log' as label,
      case when  l ->> 'enabled' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when  l ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      azure_diagnostic_setting,
      jsonb_array_elements(logs) as l
    where
      l ->> 'category' = 'Administrative'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_diagnostic_setting_security_log" {
  sql = <<-EOQ
    select
      'Security Log' as label,
      case when  l ->> 'enabled' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when  l ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      azure_diagnostic_setting,
      jsonb_array_elements(logs) as l
    where
      l ->> 'category' = 'Security'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_diagnostic_service_health_log" {
  sql = <<-EOQ
    select
      'Service Health Log' as label,
      case when  l ->> 'enabled' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when  l ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      azure_diagnostic_setting,
      jsonb_array_elements(logs) as l
    where
      l ->> 'category' = 'ServiceHealth'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_diagnostic_recommendation_log" {
  sql = <<-EOQ
    select
      'Recommendation Log' as label,
      case when  l ->> 'enabled' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when  l ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      azure_diagnostic_setting,
      jsonb_array_elements(logs) as l
    where
      l ->> 'category' = 'Recommendation'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_diagnostic_policy_log" {
  sql = <<-EOQ
    select
      'Policy Log' as label,
      case when  l ->> 'enabled' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when  l ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      azure_diagnostic_setting,
      jsonb_array_elements(logs) as l
    where
      l ->> 'category' = 'Policy'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_diagnostic_autoscale_log" {
  sql = <<-EOQ
    select
      'Autoscale Log' as label,
      case when  l ->> 'enabled' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when  l ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      azure_diagnostic_setting,
      jsonb_array_elements(logs) as l
    where
      l ->> 'category' = 'Autoscale'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_diagnostic_setting_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      event_hub_name as "Event Hub Name",
      title as "Title",
      log_analytics_destination_type as "Log Analytics Destination",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_diagnostic_setting
    where
      id = $1
  EOQ

  param "id" {}
}

node "azure_diagnostic_setting_node" {
  category = category.azure_diagnostic_setting

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group
      ) as properties
    from
      azure_diagnostic_setting
    where
      id = $1;
  EOQ

  param "id" {}
}