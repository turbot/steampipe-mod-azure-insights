locals {
  sql_common_tags = {
    service = "Azure/SQL"
  }
}

category "azure_mssql_elasticpool" {
  title = "SQL Elastic Pool"
  icon  = "text:ElasticPool"
  color = local.database_color
}

category "azure_sql_database" {
  title = "SQL Database"
  href  = "/azure_insights.dashboard.azure_sql_database_detail?input.database_id={{.properties.'ID' | @uri}}"
  icon  = "circle-stack"
  color = local.database_color
}

category "azure_sql_server" {
  title = "SQL Server"
  href  = "/azure_insights.dashboard.azure_sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon  = "circle-stack"
  color = local.database_color
}
