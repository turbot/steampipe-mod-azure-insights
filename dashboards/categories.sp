category "azure_storage_account" {
  icon = local.azure_storage_account_icon
  fold {
    title     = "Storage Account"
    icon = local.azure_storage_account_icon
    threshold = 3
  }
}

category "azure_compute_snapshot" {
  icon = local.azure_compute_snapshot_icon
  fold {
    title     = "Compute Snapshot"
    icon = local.azure_compute_snapshot_icon
    threshold = 3
  }
}

category "azure_log_profile" {
  fold {
    title     = "Log Profile"
    threshold = 3
  }
}

category "azure_subnet" {
  fold {
    title     = "Subnet"
    threshold = 3
  }
}

category "azure_virtual_network" {
  icon = local.azure_virtual_network_icon
  fold {
    title     = "Virtual Network"
    icon = local.azure_virtual_network_icon
    threshold = 3
  }
}

category "azure_storage_table" {
  fold {
    title     = "Storage Table"
    threshold = 3
  }
}

category "azure_storage_container" {
  fold {
    title     = "Storage Container"
    threshold = 3
  }
}

category "azure_storage_blob" {
  fold {
    title     = "Storage Blob"
    threshold = 3
  }
}

category "azure_diagnostic_setting" {
  fold {
    title     = "Diagnostic Setting"
    threshold = 3
  }
}

category "azure_key_vault" {
  icon = local.azure_key_vault_icon
  fold {
    title     = "Key Vault"
    icon = local.azure_key_vault_icon
    threshold = 3
  }
}

category "azure_compute_disk" {
  icon = local.azure_compute_disk_icon
  fold {
    title     = "Compute Disk"
    icon = local.azure_compute_disk_icon
    threshold = 3
  }
}

category "azure_storage_queue" {
  fold {
    title     = "Storage Queue"
    threshold = 3
  }
}

category "azure_route_table" {
  fold {
    title     = "Route Table"
    threshold = 3
  }
}

category "azure_network_security_group" {
  fold {
    title     = "Network Security Group"
    threshold = 3
  }
}