locals {
  keyvault_common_tags = {
    service = "Azure/KeyVault"
  }
}

category "key_vault_key" {
  title = "Key Vault Key"
  color = local.security_color
  href  = "/azure_insights.dashboard.key_vault_key_detail?input.key_vault_key_id={{.properties.'Key ID' | @uri}}"
  icon  = "key"
}

category "key_vault_key_verison" {
  title = "Key Version"
  color = local.security_color
  icon  = "difference"
}

category "key_vault_secret" {
  title = "Key Vault Secret"
  color = local.security_color
  icon  = "password"
}

category "key_vault" {
  title = "Key Vault"
  color = local.security_color
  href  = "/azure_insights.dashboard.key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = "shelves"
}
