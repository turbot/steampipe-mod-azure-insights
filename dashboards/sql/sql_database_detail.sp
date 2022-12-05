dashboard "sql_database_detail" {

  title         = "Azure SQL Database Detail"
  documentation = file("./dashboards/sql/docs/sql_database_detail.md")

  tags = merge(local.sql_common_tags, {
    type = "Detail"
  })

  input "sql_database_id" {
    title = "Select a database:"
    query = query.sql_database_input
    width = 4
  }

  container {


    card {
      width = 2
      query = query.sql_database_server
      args = {
        id = self.input.sql_database_id.value
      }
    }

    card {
      width = 2
      query = query.sql_database_status
      args = {
        id = self.input.sql_database_id.value
      }
    }

    card {
      width = 2
      query = query.sql_database_zone_redundant
      args = {
        id = self.input.sql_database_id.value
      }
    }

    card {
      width = 2
      query = query.sql_database_transparent_data_encryption
      args = {
        id = self.input.sql_database_id.value
      }
    }

    card {
      width = 2
      query = query.sql_database_vulnerability_assessment_enabled
      args = {
        id = self.input.sql_database_id.value
      }
    }

    card {
      width = 2
      query = query.sql_database_geo_redundant_backup_enabled
      args = {
        id = self.input.sql_database_id.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "sql_servers" {
        sql = <<-EOQ
          with sql_servers as (
            select
              id,
              name,
              kind,
              location,
              public_network_access,
              resource_group,
              subscription_id,
              version,
              type,
              title
            from
              azure_sql_server
          )
          select
            lower(sv.id) as sql_server_id,
            sv.title as title,
            json_build_object(
              'Name', sv.name,
              'Kind', sv.kind,
              'Location', sv.location,
              'Public Network Access', sv.public_network_access,
              'Resource Group', sv.resource_group,
              'Subscription ID', sv.subscription_id,
              'Version', sv.version,
              'Type', sv.type,
              'ID', sv.id
            ) as properties
          from
            azure_sql_database as db,
            sql_servers as sv
          where
            lower(db.id) = lower($1)
            and db.server_name = sv.name;
        EOQ

        args = [self.input.sql_database_id.value]
      }

      nodes = [
        node.sql_database_mssql_elasticpool,
        node.sql_database,
        node.sql_server
      ]

      edges = [
        edge.sql_database_to_mssql_elasticpool,
        edge.sql_server_to_sql_database
      ]

      args = {
        id               = self.input.sql_database_id.value
        sql_database_ids = [self.input.sql_database_id.value]
        sql_server_ids   = with.sql_servers.rows[*].sql_server_id
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
        query = query.sql_database_overview
        args = {
          id = self.input.sql_database_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.sql_database_tags
        args = {
          id = self.input.sql_database_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Retention Policy"
        query = query.sql_database_retention
        args = {
          id = self.input.sql_database_id.value
        }
      }

      table {
        title = "Vulnerability Assessment"
        query = query.sql_database_vulnerability_assessment
        args = {
          id = self.input.sql_database_id.value
        }
      }

    }
  }

}

query "sql_database_input" {
  sql = <<-EOQ
    select
      d.title as label,
      lower(d.id) as value,
      json_build_object(
        'subscription', sub.display_name,
        'resource_group', d.resource_group,
        'region', d.region
      ) as tags
    from
      azure_sql_database as d,
      azure_subscription as sub
    where
      lower(d.subscription_id) = lower(sub.subscription_id)
      and name <> 'master'
    order by
      d.title;
  EOQ
}

query "sql_database_server" {
  sql = <<-EOQ
    select
      'Server Name' as label,
      server_name as value
    from
      azure_sql_database
    where
      name <> 'master'
      and lower(id) = $1;
  EOQ

  param "id" {}

}

query "sql_database_zone_redundant" {
  sql = <<-EOQ
    select
      'Zone Redundancy' as label,
      case when zone_redundant then 'Enabled' else 'Disabled' end as value
    from
      azure_sql_database
    where
      name <> 'master'
      and lower(id) = $1;
  EOQ

  param "id" {}

}

query "sql_database_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      status as value
    from
      azure_sql_database
    where
      name <> 'master'
      and lower(id) = $1;
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
      and lower(id) = $1;
  EOQ

  param "id" {}
}

query "sql_database_transparent_data_encryption" {
  sql = <<-EOQ
    select
      'TDE' as label,
      case when transparent_data_encryption ->> 'status' = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when transparent_data_encryption ->> 'status' = 'Enabled' then 'ok' else 'alert' end as type
    from
      azure_sql_database
    where
      name <> 'master'
      and lower(id) = $1;
  EOQ

  param "id" {}
}

query "sql_database_vulnerability_assessment_enabled" {
  sql = <<-EOQ
    with sql_database_va as (
      select
        distinct id
      from
        azure_sql_database as d,
        jsonb_array_elements(vulnerability_assessments) as va
      where
        va -> 'properties' -> 'recurringScans' ->> 'isEnabled' = 'true'
    )
    select
      'Vulnerability Assessment' as label,
      case when v.id is not null then 'Enabled' else 'Disabled' end as value,
      case when v.id is not null then 'ok' else 'alert' end as type
    from
     azure_sql_database as d left join sql_database_va as v on lower(v.id) = lower(d.id)
    where
      d.name <> 'master'
      and lower(d.id) = $1;
  EOQ

  param "id" {}
}

query "sql_database_geo_redundant_backup_enabled" {
  sql = <<-EOQ
    select
      'Geo-Redundant Backup' as label,
      case when
        (retention_policy_property ->> 'monthlyRetention' <> 'PT0S'
        or retention_policy_property ->> 'weeklyRetention' <> 'PT0S'
        or retention_policy_property ->> 'yearlyRetention' <> 'PT0S')
        then 'Enabled' else 'Disabled' end as value,
      case when
        (retention_policy_property ->> 'monthlyRetention' <> 'PT0S'
        or retention_policy_property ->> 'weeklyRetention' <> 'PT0S'
        or retention_policy_property ->> 'yearlyRetention' <> 'PT0S')
        then 'ok' else 'alert' end as type
    from
      azure_sql_database
    where
      name <> 'master'
      and lower(id) = $1;
  EOQ

  param "id" {}
}

node "sql_database_mssql_elasticpool" {
  category = category.mssql_elasticpool

  sql = <<-EOQ
    with sql_pools as (
      select
        id,
        title,
        name,
        type,
        edition,
        kind,
        region,
        state,
        zone_redundant
      from
        azure_mssql_elasticpool
    )
    select
      lower(sp.id) as id,
      sp.title as title,
      json_build_object(
        'Edition', sp.edition,
        'State', sp.state,
        'Zone Redundant', sp.zone_redundant,
        'Type', sp.type,
        'ID', sp.id
      ) as properties
    from
      azure_sql_database as db,
      sql_pools as sp
    where
      lower(db.id) = any($1)
      and lower(sp.name) = lower(db.elastic_pool_name);
  EOQ

  param "sql_database_ids" {}
}

edge "sql_database_to_mssql_elasticpool" {
  title = "elasticpool"
  sql   = <<-EOQ
    with sql_pools as (
      select
        id,
        name
      from
        azure_mssql_elasticpool
    )
    select
      lower(sp.id) as to_id,
      lower(db.id) as from_id
    from
      azure_sql_database as db,
      sql_pools as sp
    where
      lower(db.id) = any($1)
      and lower(sp.name) = lower(db.elastic_pool_name);
  EOQ
  param "sql_database_ids" {}
}

query "sql_database_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      database_id as "Database ID",
      kind as "Kind",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_sql_database
    where
      name <> 'master'
      and lower(id) = $1;
  EOQ

  param "id" {}
}

query "sql_database_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_sql_database,
      jsonb_each_text(tags) as tag
    where
      name <> 'master'
      and lower(id) = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "sql_database_retention" {
  sql = <<-EOQ
    select
      retention_policy_name as "Retention Policy Name",
      retention_policy_property ->> 'monthlyRetention' as "Monthly Retention",
      retention_policy_property ->> 'weekOfYear' as "Week Of Year",
      retention_policy_property ->> 'weeklyRetention' as "Weekly Retention",
      retention_policy_property ->> 'Yearly Retention' as "Yearly Retention",
      retention_policy_id as "Retention Policy ID"
    from
      azure_sql_database
    where
      name <> 'master'
      and lower(id) = $1;
  EOQ

  param "id" {}
}

query "sql_database_vulnerability_assessment" {
  sql = <<-EOQ
    select
      a ->> 'name' as "Name",
      a -> 'recurringScans' ->> 'emailSubscriptionAdmins' as "Email Subscription Admins",
      a -> 'recurringScans' ->> 'isEnabled' as "Is Enabled",
      a ->> 'type'  as "Type",
      a ->> 'id' as "ID"
    from
      azure_sql_database,
      jsonb_array_elements(vulnerability_assessments) as a
    where
      name <> 'master'
      and lower(id) = $1;
  EOQ

  param "id" {}
}
