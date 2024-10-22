locals {
  sql_common_tags = {
    service = "Azure/SQL"
  }
}

category "mssql_elasticpool" {
  title = "SQL Elastic Pool"
  color = local.database_color
  icon  = "device_hub"
}

category "sql_database" {
  title = "SQL Database"
  color = local.database_color
  href  = "/azure_insights.dashboard.sql_database_detail?input.database_id={{.properties.'ID' | @uri}}"
  icon  = "database"
}

category "sql_server" {
  title = "SQL Server"
  color = local.database_color
  href  = "/azure_insights.dashboard.sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon  = "storage"
}
