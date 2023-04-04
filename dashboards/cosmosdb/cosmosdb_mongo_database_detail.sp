dashboard "cosmosdb_mongo_database_detail" {

  title         = "Azure CosmosDB Mongo Database Detail"
  documentation = file("./dashboards/cosmosdb/docs/cosmosdb_mongo_database_detail.md")

  tags = merge(local.cosmosdb_common_tags, {
    type = "Detail"
  })

  input "cosmosdb_mongo_database_id" {
    title = "Select a database:"
    query = query.cosmosdb_mongo_database_input
    width = 4
  }

  container {


    card {
      width = 2
      query = query.cosmosdb_mongo_database_collection_count
      args  = [self.input.cosmosdb_mongo_database_id.value]
    }

    card {
      width = 2
      query = query.cosmosdb_mongo_database_throughput
      args  = [self.input.cosmosdb_mongo_database_id.value]
    }

  }

  with "cosmosdb_account_for_cosmosdb_mongo_database" {
    query = query.cosmosdb_account_for_cosmosdb_mongo_database
    args  = [self.input.cosmosdb_mongo_database_id.value]
  }

  with "cosmosdb_mongo_collection_for_cosmosdb_mongo_database" {
    query = query.cosmosdb_mongo_collection_for_cosmosdb_mongo_database
    args  = [self.input.cosmosdb_mongo_database_id.value]
  }

  container {
    graph {
      title = "Relationships"
      type  = "graph"

      node {
        base = node.cosmosdb_mongo_database
        args = {
          cosmosdb_mongo_database_ids = [self.input.cosmosdb_mongo_database_id.value]
        }
      }

      node {
        base = node.cosmosdb_mongo_collection
        args = {
          cosmosdb_mongo_database_ids = [self.input.cosmosdb_mongo_database_id.value]
        }
      }

      node {
        base = node.cosmosdb_account
        args = {
          cosmosdb_account_ids = with.cosmosdb_account_for_cosmosdb_mongo_database.rows[*].account_id
        }
      }

      edge {
        base = edge.cosmosdb_mongo_database_to_cosmosdb_mongo_collection
        args = {
          cosmosdb_mongo_database_ids = [self.input.cosmosdb_mongo_database_id.value]
        }
      }

      edge {
        base = edge.cosmosdb_account_to_cosmosdb_mongo_database
        args = {
          cosmosdb_account_ids = with.cosmosdb_account_for_cosmosdb_mongo_database.rows[*].account_id
        }
      }
    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 3
        query = query.cosmosdb_mongo_database_overview
        args  = [self.input.cosmosdb_mongo_database_id.value]
      }

      table {
        title = "Tags"
        width = 3
        query = query.cosmosdb_mongo_database_tags
        args  = [self.input.cosmosdb_mongo_database_id.value]
      }

      table {
        title = "Account Details"
        width = 6
        query = query.cosmosdb_mongo_database_account_details
        args  = [self.input.cosmosdb_mongo_database_id.value]

        column "lower_id" {
          display = "none"
        }

        column "Name" {
          href = "/azure_insights.dashboard.cosmosdb_account_detail?input.cosmosdb_account_id={{ .'lower_id' | @uri }}"
        }
      }
    }

    container {
      width = 12

      table {
        title = "Collection Details"
        query = query.cosmosdb_mongo_database_collection_details
        args  = [self.input.cosmosdb_mongo_database_id.value]
      }

      table {
        title = "Throughput Settings"
        query = query.cosmosdb_mongo_database_throughput_settings
        args  = [self.input.cosmosdb_mongo_database_id.value]
      }

    }
  }

}

query "cosmosdb_mongo_database_input" {
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
      azure_cosmosdb_mongo_database as d,
      azure_subscription as sub
    where
      lower(d.subscription_id) = lower(sub.subscription_id)
      and name <> 'master'
    order by
      d.title;
  EOQ
}

# card queries

query "cosmosdb_mongo_database_collection_count" {
  sql = <<-EOQ
    select
      'Collection Count' as label,
      count(*) as value
    from
      azure_cosmosdb_mongo_database d,
      azure_cosmosdb_mongo_collection c
    where
      lower(d.id) = $1
      and c.database_name = d.name;
  EOQ
}

query "cosmosdb_mongo_database_throughput" {
  sql = <<-EOQ
    select
      'Throughput - (RU/s)' as label,
      throughput_settings ->> 'ResourceThroughput' as value
    from
      azure_cosmosdb_mongo_database
    where
      lower(id) = $1;
  EOQ
}

# with queries

query "cosmosdb_account_for_cosmosdb_mongo_database" {
  sql = <<-EOQ
    select
      lower(a.id) as account_id
    from
      azure_cosmosdb_mongo_database d,
      azure_cosmosdb_account as a
    where
      d.resource_group = a.resource_group
      and d.subscription_id = a.subscription_id
      and account_name = a.name
      and lower(d.id) = $1;
  EOQ
}

query "cosmosdb_mongo_collection_for_cosmosdb_mongo_database" {
  sql = <<-EOQ
    select
      lower(c.id) as collection_id
    from
      azure_cosmosdb_mongo_database as d
      join azure_cosmosdb_mongo_collection as c 
        on c.database_name = d.name
        and c.account_name = (select account_name from azure_cosmosdb_mongo_database where lower(id) = $1)
    where
      lower(d.id) = $1;
  EOQ
}

# table queries

query "cosmosdb_mongo_database_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      database_id as "Database ID",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_cosmosdb_mongo_database
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_mongo_database_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_cosmosdb_mongo_database,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
  EOQ
}

query "cosmosdb_mongo_database_throughput_settings" {
  sql = <<-EOQ
    select
      throughput_settings ->> 'Name' as "Name",
      throughput_settings ->> 'ResourceThroughput' as "Throughput - (RU/s)", 
      throughput_settings ->> 'AutoscaleSettingsMaxThroughput' as "Maximum Throughput - (RU/s)",
      throughput_settings ->> 'ResourceMinimumThroughput' as "Minimum Throughput - (RU/s)",
      throughput_settings ->> 'ID' as "ID"
    from
      azure_cosmosdb_mongo_database
    where
      lower(id) = $1;
  EOQ
}

query "cosmosdb_mongo_database_collection_details" {
  sql = <<-EOQ
    select
      c.name as "Name",
      c.account_name as "Account Name",
      c.analytical_storage_ttl as "Analytical Storage TTL",
      c.throughput_settings ->> 'Throughput' as "Throughput - (RU/s)",
      c.shard_key as "Shard Key",
      c.id as "ID"
    from
      azure_cosmosdb_mongo_database as d
      join azure_cosmosdb_mongo_collection as c on d.name = c.database_name
    where
      lower(d.id) = $1
      and c.account_name in (select account_name from azure_cosmosdb_mongo_database where lower(id) = $1);
  EOQ
}

query "cosmosdb_mongo_database_account_details" {
  sql = <<-EOQ
    select
      a.name as "Name",
      a.kind as "Kind",
      a.server_version as "Server Version",
      database_account_offer_type as "Offer Type",
      a.id as "ID",
      lower(a.id) as lower_id
    from
      azure_cosmosdb_mongo_database d,
      azure_cosmosdb_account as a
    where
      d.resource_group = a.resource_group
      and d.subscription_id = a.subscription_id
      and account_name = a.name
      and lower(d.id) = $1;
  EOQ
}