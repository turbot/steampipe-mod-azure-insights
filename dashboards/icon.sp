locals {
  azure_key_vault_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/azure_key_vault_light.svg"))
  azure_key_vault_firewall_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/azure_network_acl_light.svg"))
  azure_key_vault_key_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/azure_key_vault_light.svg"))
  azure_key_vault_secret_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/azure_key_vault_light.svg"))
}
