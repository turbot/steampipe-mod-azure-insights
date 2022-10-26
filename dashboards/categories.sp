category "azure_virtual_network" {
  icon = local.azure_virtual_network_icon
  fold {
    title     = "Virtual Networks"
    threshold = 3
  }
}

category "azure_subnet" {
  fold {
    title     = "Subnets"
    threshold = 3
  }
}

category "azure_sql_server" {
  icon = local.azure_sql_server_icon
  fold {
    title     = "SQL Servers"
    threshold = 3
  }
}

category "azure_sql_server_firewall" {
  fold {
    title     = "SQL Server Firewalls"
    threshold = 3
  }
}

category "azure_sql_database" {
  icon = local.azure_sql_database_icon
  fold {
    title     = "SQL Databases"
    threshold = 3
  }
}

category "azure_key_vault" {
  icon = local.azure_key_vault_icon
  fold {
    title     = "Key Vaults"
    threshold = 3
  }
}

category "azure_key_vault_key" {
  fold {
    title     = "Keys"
    threshold = 3
  }
}