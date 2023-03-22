locals {
  documentdb_cosmosdb_common_tags = {
    service = "Azure/CosmosDB"
  }
}

category "documentdb_cosmosdb_account" {
  title = "Cosmos DB Account"
  color = local.database_color
  icon  = "circle_stack"
}
