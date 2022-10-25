locals {
  azure_key_vault_icon       = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/key_vault.svg"))
  azure_sql_server_icon      = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/sql_server.svg"))
  azure_virtual_network_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/virtual_network.svg"))
}
