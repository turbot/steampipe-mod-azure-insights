locals {
  cosmosdb_common_tags = {
    service = "Azure/CosmosDB"
  }
}

category "cosmosdb_account" {
  title = "Cosmos DB Account"
  color = local.database_color
  icon  = "circle_stack"
}

category "cosmosdb_mongo_database" {
  title = "Cosmos DB Mongo Database"
  color = local.database_color
  icon  = "circle_stack"
}

category "cosmosdb_sql_database" {
  title = "Cosmos DB SQL Database"
  color = local.database_color
  icon  = "circle_stack"
}
