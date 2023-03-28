dashboard "cosmosdb_mongo_database_dashboard" {

  title         = "Azure CosmosDB Mongo Database Dashboard"
  documentation = file("./dashboards/cosmosdb/docs/cosmosdb_mongo_database_dashboard.md")

  tags = merge(local.cosmosdb_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.cosmosdb_mongo_database_count
      width = 3
    }

    card {
      query = query.cosmosdb_mongo_database_autoscaling_disabled_count
      width = 3
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Databases by Subscription"
      query = query.cosmosdb_mongo_database_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Databases by Resource Group"
      query = query.cosmosdb_mongo_database_by_resource_group
      type  = "column"
      width = 3
    }

    chart {
      title = "Databases by Region"
      query = query.cosmosdb_mongo_database_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Databases by Account"
      query = query.cosmosdb_mongo_database_by_account
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "cosmosdb_mongo_database_count" {
  sql = <<-EOQ
    select count(*) as "Databases" from azure_cosmosdb_mongo_database;
  EOQ
}

query "cosmosdb_mongo_database_autoscaling_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Autoscaling Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_cosmosdb_mongo_database
    where
      autoscale_settings_max_throughput is null;
  EOQ
}

# Analysis Queries

query "cosmosdb_mongo_database_by_subscription" {
  sql = <<-EOQ
    select
      s.title as "Subscription",
      count(d.*) as "Databases"
    from
      azure_cosmosdb_mongo_database as d,
      azure_subscription as s
    where
      s.subscription_id = d.subscription_id
    group by
      s.title
    order by
      s.title;
  EOQ
}

query "cosmosdb_mongo_database_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(d.*) as "Databases"
    from
      azure_cosmosdb_mongo_database as d,
      azure_subscription as sub
    where
       d.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "cosmosdb_mongo_database_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Databases"
    from
      azure_cosmosdb_mongo_database
    group by
      region
    order by
      region;
  EOQ
}

query "cosmosdb_mongo_database_by_account" {
  sql = <<-EOQ
    select
      account_name as "Account Name",
      count(account_name) as "Databases"
    from
      azure_cosmosdb_mongo_database
    group by
      account_name
    order by
      account_name;
  EOQ
}

