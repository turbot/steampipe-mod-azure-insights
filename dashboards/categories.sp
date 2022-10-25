category "azure_key_vault" {
  href = "/azure_insights.dashboard.azure_key_vault_detail?input.key_vault_id={{.properties.'Vault Id' | @uri}}"
  icon = local.azure_key_vault_icon
  fold {
    title     = "Key Vault"
    threshold = 3
  }
}

category "azure_key_vault_firewall" {
  icon = local.azure_key_vault_firewall_icon
  fold {
    title     = "Networking Firewalls"
    icon      = local.azure_key_vault_firewall_icon
    threshold = 3
  }
}

category "azure_key_vault_key" {
  # icon = local.azure_key_vault_key_icon
  fold {
    title     = "Keys"
    # icon      = local.azure_key_vault_key_icon
    threshold = 1
  }
}

graph "azure_graph_categories" {
  type  = "graph"
  title = "Relationships"
}
