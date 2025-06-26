dashboard "sql_server_inventory_report" {

  title         = "Azure SQL Server Inventory Report"
  documentation = file("./dashboards/sql/docs/sql_server_report_inventory.md")

  tags = merge(local.sql_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.sql_server_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.sql_server_detail.url_path}?input.server_id={{.'ID' | @uri}}"
    }

    query = query.sql_server_inventory_table
  }
}

query "sql_server_inventory_table" {
  sql = <<-EOQ
    select
      s.name as "Name",
      s.state as "State",
      s.version as "Version",
      s.administrator_login as "Administrator Login",
      s.minimal_tls_version as "Minimal TLS Version",
      s.public_network_access as "Public Network Access",
      s.fully_qualified_domain_name as "Fully Qualified Domain Name",
      jsonb_array_length(s.firewall_rules) as "Firewall Rules",
      jsonb_array_length(s.virtual_network_rules) as "Virtual Network Rules",
      s.tags as "Tags",
      lower(s.id) as "ID",
      sub.title as "Subscription",
      s.subscription_id as "Subscription ID",
      s.resource_group as "Resource Group",
      s.region as "Region"
    from
      azure_sql_server as s,
      azure_subscription as sub
    where
      sub.subscription_id = s.subscription_id
    order by
      s.name;
  EOQ
} 