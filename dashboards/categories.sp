category "azure_storage_account" {
  icon = local.azure_storage_account_icon
  fold {
    title     = "Storage Accounts"
    icon = local.azure_storage_account_icon
    threshold = 3
  }
}

category "azure_compute_virtual_machine" {
  icon = local.azure_compute_virtual_machine_icon
  fold {
    title     = "Compute Virtual Machines"
    icon = local.azure_compute_virtual_machine_icon
    threshold = 3
  }
}

category "azure_compute_snapshot" {
  icon = local.azure_compute_snapshot_icon
  fold {
    title     = "Compute Snapshots"
    icon = local.azure_compute_snapshot_icon
    threshold = 3
  }
}

category "azure_log_profile" {
  fold {
    title     = "Log Profiles"
    threshold = 3
  }
}

category "azure_network_interface" {
  icon = local.azure_network_interface_icon
  fold {
    title     = "Network Interfaces"
    icon      = local.azure_network_interface_icon
    threshold = 3
  }
}

category "azure_subnet" {
  fold {
    title     = "Subnets"
    threshold = 3
  }
}

category "azure_public_ip" {
  icon = local.azure_public_ip_icon
  fold {
    title     = "Public IPs"
    icon      = local.azure_public_ip_icon
    threshold = 3
  }
}

category "azure_virtual_network" {
  icon = local.azure_virtual_network_icon
  fold {
    title     = "Virtual Networks"
    icon      = local.azure_virtual_network_icon
    threshold = 3
  }
}

category "azure_image" {
  icon = local.azure_image_icon
  fold {
    title     = "Compute Images"
    icon      = local.azure_image_icon
    threshold = 3
  }
}

category "azure_storage_table" {
  fold {
    title     = "Storage Tables"
    threshold = 3
  }
}

category "azure_storage_container" {
  fold {
    title     = "Storage Containers"
    threshold = 3
  }
}

category "azure_storage_blob" {
  fold {
    title     = "Storage Blobs"
    threshold = 3
  }
}

category "azure_diagnostic_setting" {
  fold {
    title     = "Diagnostic Settings"
    threshold = 3
  }
}

category "azure_key_vault" {
  icon = local.azure_key_vault_icon
  fold {
    title     = "Key Vaults"
    icon      = local.azure_key_vault_icon
    threshold = 3
  }
}

category "azure_compute_disk" {
  icon = local.azure_compute_disk_icon
  fold {
    title     = "Compute Disks"
    icon      = local.azure_compute_disk_icon
    threshold = 3
  }
}

category "azure_storage_queue" {
  fold {
    title     = "Storage Queues"
    threshold = 3
  }
}

category "azure_route_table" {
  fold {
    title     = "Route Tables"
    threshold = 3
  }
}

category "azure_network_security_group" {
  icon = local.azure_network_security_group_icon
  fold {
    title     = "Network Security Groups"
    icon = local.azure_network_security_group_icon
    threshold = 3
  }
}

category "azure_sql_server" {
  icon = local.azure_sql_server_icon
  fold {
    title     = "SQL Servers"
    icon      = local.azure_sql_server_icon
    threshold = 3
  }
}

category "azure_sql_server_firewall" {
  fold {
    title     = "SQL Server Firewalls"
    threshold = 3
  }
}

category "azure_sql_server_audit_policy" {
  fold {
    title     = "SQL Server Audit Policies"
    threshold = 3
  }
}

category "azure_sql_server_private_endpoint_connection" {
  fold {
    title     = "SQL Server Private Endpoint Connection"
    threshold = 3
  }
}

category "azure_sql_database" {
  icon = local.azure_sql_database_icon
  fold {
    title     = "SQL Databases"
    icon      = local.azure_sql_database_icon
    threshold = 3
  }
}

category "azure_key_vault_key" {
  fold {
    title     = "Keys"
    threshold = 3
  }
}