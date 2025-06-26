dashboard "sql_database_inventory_report" {

  title         = "Azure SQL Database Inventory Report"
  documentation = file("./dashboards/sql/docs/sql_database_report_inventory.md")

  tags = merge(local.sql_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.sql_database_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.sql_database_detail.url_path}?input.database_id={{.'ID' | @uri}}"
    }

    query = query.sql_database_inventory_table
  }
}

query "sql_database_inventory_table" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.server_name as "Server Name",
      d.status as "Status",
      d.creation_date as "Creation Date",
      d.edition as "Edition",
      d.elastic_pool_name as "Elastic Pool Name",
      d.requested_service_objective_name as "Service Tier",
      d.max_size_bytes as "Max Size Bytes",
      d.zone_redundant as "Zone Redundant",
      d.read_scale as "Read Scale",
      d.tags as "Tags",
      lower(d.id) as "ID",
      sub.title as "Subscription",
      d.subscription_id as "Subscription ID",
      d.resource_group as "Resource Group",
      d.region as "Region"
    from
      azure_sql_database as d,
      azure_subscription as sub
    where
      sub.subscription_id = d.subscription_id
    order by
      d.name;
  EOQ
} 