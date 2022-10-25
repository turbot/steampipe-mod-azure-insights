category "azure_virtual_network" {
  icon = local.azure_virtual_network_icon
  fold {
    title     = "Virtual networks"
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
    title     = "SQL server"
    threshold = 3
  }
}

category "azure_key_vault" {
  icon = local.azure_key_vault_icon
  fold {
    title     = "Key vault"
    threshold = 3
  }
}

category "azure_key_vault_key" {
  fold {
    title     = "Keys"
    threshold = 3
  }
}