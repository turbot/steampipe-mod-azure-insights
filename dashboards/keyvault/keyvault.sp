locals {
  keyvault_common_tags = {
    service = "Azure/KeyVault"
  }
}

category "key_vault_key_verison" {
  title = "Key Version"
  icon  = "key"
  color = local.security_color
}

category "key_vault_key" {
  href  = "/azure_insights.dashboard.key_vault_key_detail?input.key_vault_key_id={{.properties.'Key ID' | @uri}}"
  title = "Key Vault Key"
  icon  = "key"
  color = local.security_color
}

category "key_vault_secret" {
  title = "Key Vault Secret"
  icon  = "text:Secret"
  color = local.security_color
}

category "key_vault" {
  title = "Key Vault"
  href  = "/azure_insights.dashboard.key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = "text:KV"
  color = local.security_color
}