locals {
  sql_common_tags = {
    service = "Azure/SQL"
  }
}

category "mssql_elasticpool" {
  title = "SQL Elastic Pool"
  icon  = "text:ElasticPool"
  color = local.database_color
}

category "sql_database" {
  title = "SQL Database"
  href  = "/azure_insights.dashboard.sql_database_detail?input.database_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:circle-stack"
  color = local.database_color
}

category "sql_server" {
  title = "SQL Server"
  href  = "/azure_insights.dashboard.sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:circle-stack"
  color = local.database_color
}
