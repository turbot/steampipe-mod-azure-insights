locals {
  cosmosdb_common_tags = {
    service = "Azure/CosmosDB"
  }
}

category "cosmosdb_account" {
  title = "Cosmos DB Account"
  color = local.database_color
  icon  = "tenancy"
  href  = "/azure_insights.dashboard.cosmosdb_account_detail?input.cosmosdb_account_id={{.properties.'ID' | @uri}}"
}

category "cosmosdb_mongo_collection" {
  title = "Cosmos DB Mongo Collection"
  color = local.database_color
  icon  = "table"
}

category "cosmosdb_mongo_database" {
  title = "Cosmos DB Mongo Database"
  color = local.database_color
  icon  = "database"
  href  = "/azure_insights.dashboard.cosmosdb_mongo_database_detail?input.cosmosdb_mongo_database_id={{.properties.'ID' | @uri}}"
}

category "cosmosdb_sql_database" {
  title = "Cosmos DB SQL Database"
  color = local.database_color
  icon  = "database"
}

category "cosmosdb_restorable_database_account" {
  title = "Cosmos Restorable Database Account"
  color = local.database_color
  icon  = "settings_backup_restore"
}
