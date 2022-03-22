dashboard "azure_sql_database_detail" {

  title         = "Azure SQL Database Detail"
  documentation = file("./dashboards/sql/docs/sql_database_detail.md")

  tags = merge(local.sql_common_tags, {
    type = "Detail"
  })

  input "database_id" {
    title = "Select a database:"
    query = query.azure_sql_database_input
    width = 4
  }

  container {


    card {
      width = 2
      query = query.azure_sql_database_server
      args = {
        id = self.input.database_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_database_status
      args = {
        id = self.input.database_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_database_kind
      args = {
        id = self.input.database_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_database_transparent_data_encryption
      args = {
        id = self.input.database_id.value
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
        query = query.azure_sql_database_overview
        args = {
          id = self.input.database_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_sql_database_tags
        args = {
          id = self.input.database_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Configurations"
        query = query.azure_sql_database_configurations
        args = {
          id = self.input.database_id.value
        }
      }


    }
  }

  container {
    width = 12

    table {
      title = "Retention Configurations"
      query = query.azure_sql_database_retention
      args = {
        id = self.input.database_id.value
      }
    }

  }

    container {
    width = 12

    table {
      title = "Vulnerability Assessment"
      query = query.azure_sql_database_vulnerability_assessment
      args = {
        id = self.input.database_id.value
      }
    }

  }

}

query "azure_sql_database_input" {
  sql = <<-EOQ
    select
      d.title as label,
      d.id as value,
      json_build_object(
        'subscription', sub.display_name,
        'resource_group', d.resource_group,
        'region', d.region
      ) as tags
    from
      azure_sql_database as d,
      azure_subscription as sub
    where
      d.subscription_id = sub.subscription_id
      and name <> 'master'
    order by
      d.title;
  EOQ
}

query "azure_sql_database_server" {
  sql = <<-EOQ
    select
      'Server Name' as label,
      server_name as value
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}

}

query "azure_sql_database_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      status as value
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}

}

query "azure_sql_database_kind" {
  sql = <<-EOQ
    select
      'Kind' as label,
      kind as value
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_database_edition" {
  sql = <<-EOQ
    select
      'Edition' as label,
      edition as value
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_database_transparent_data_encryption" {
  sql = <<-EOQ
    select
      'TDE' as label,
      case when transparent_data_encryption ->> 'status' = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when transparent_data_encryption ->> 'status' = 'Enabled'then 'ok' else 'alert' end as type
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_database_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      database_id as "Database ID",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_database_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_sql_database,
      jsonb_each_text(tags) as tag
    where
      name <> 'master'
      and id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_sql_database_configurations" {
  sql = <<-EOQ
    select
      read_scale as "Read Scale",
      max_size_bytes as "Max Size Bytes",
      containment_state as "Containment State"
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_database_retention" {
  sql = <<-EOQ
    select
      retention_policy_name  as "Retention Policy Name",
      retention_policy_property ->> 'monthlyRetention' as "Monthly Retention",
      retention_policy_property ->> 'weekOfYear' as "Week Of Year",
      retention_policy_property ->> 'weeklyRetention' as "Weekly Retention",
      retention_policy_property ->> 'Yearly Retention' as "yearlyRetention",
      retention_policy_id as "TRetention Policy IDype"
    from
      azure_sql_database
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_database_vulnerability_assessment" {
  sql = <<-EOQ
    select
      a ->> 'id' as "ID",
      a ->> 'name' as "Name",
      a -> 'recurringScans' -> 'emailSubscriptionAdmins' as "Email Subscription Admins",
      a -> 'recurringScans' ->> 'isEnabled' as "Is Enabled",
      a -> 'type'  as "Type"
    from
      azure_sql_database,
      jsonb_array_elements(vulnerability_assessments) as a
    where
      name <> 'master'
      and id = $1;
  EOQ

  param "id" {}
}