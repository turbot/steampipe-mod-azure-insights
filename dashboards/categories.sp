category "azure_api_management" {
  fold {
    title     = "API Managements"
    threshold = 3
  }
}

category "azure_application_gateway" {
  icon = local.azure_application_gateway_icon
  fold {
    title     = "Application Gateways"
    icon      = local.azure_application_gateway_icon
    threshold = 3
  }
}

category "azure_app_service_web_app" {
  icon = local.azure_app_service_web_app_icon
  href = "/azure_insights.dashboard.azure_app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  fold {
    title     = "Web Apps"
    icon      = local.azure_app_service_web_app_icon
    threshold = 3
  }
}

category "azure_app_service_plan" {
  icon = local.azure_app_service_plan_icon
  fold {
    title     = "App Service Plans"
    icon      = local.azure_app_service_plan_icon
    threshold = 3
  }
}

category "azure_container_registry" {
  fold {
    title     = "Container Registries"
    threshold = 3
  }
}

category "azure_compute_disk" {
  href  = "/azure_insights.dashboard.azure_compute_disk_detail?input.d_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_compute_disk_icon
  color = "green"
  fold {
    title     = "Compute Disks"
    icon      = local.azure_compute_disk_icon
    threshold = 3
  }
}

category "azure_compute_snapshot" {
  href  = "/azure_insights.dashboard.azure_compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon  = local.azure_compute_snapshot_icon
  color = "green"
  fold {
    title     = "Compute Snapshots"
    icon      = local.azure_compute_snapshot_icon
    threshold = 3
  }
}

category "azure_compute_virtual_machine" {
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_compute_virtual_machine_icon
  color = "orange"
  fold {
    title     = "Compute Virtual Machines"
    icon      = local.azure_compute_virtual_machine_icon
    threshold = 3
  }
}

category "azure_cosmosdb_account" {
  icon = local.azure_cosmosdb_account_icon
  fold {
    title     = "Cosmos DB Accounts"
    icon      = local.azure_cosmosdb_account_icon
    threshold = 3
  }
}

category "azure_diagnostic_setting" {
  fold {
    title     = "Diagnostic Settings"
    threshold = 3
  }
}

category "azure_eventhub_namespace" {
  fold {
    title     = "EventHub Namespaces"
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

category "azure_key_vault" {
  href  = "/azure_insights.dashboard.azure_key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_key_vault_icon
  color = "red"
  fold {
    title     = "Key Vaults"
    icon      = local.azure_key_vault_icon
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
  icon  = local.azure_key_vault_key_icon
  color = "red"
  fold {
    title     = "Keys"
    threshold = 3
  }
}

category "azure_key_vault_secret" {
  fold {
    title     = "Secrets"
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
  href  = "/azure_insights.dashboard.azure_network_interface_detail?input.nic_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_network_interface_icon
  color = "purple"
  fold {
    title     = "Network Interfaces"
    icon      = local.azure_network_interface_icon
    threshold = 3
  }
}

category "azure_network_security_group" {
  href  = "/azure_insights.dashboard.azure_network_security_group_detail?input.nsg_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-solid:lock-closed"
  color = "purple"
  fold {
    title     = "Network Security Groups"
    icon      = "heroicons-solid:lock-closed"
    threshold = 3
  }
}

category "azure_postgresql_server" {
  fold {
    title     = "Postgresql Servers"
    threshold = 3
  }
}

category "azure_public_ip" {
  href  = "/azure_insights.dashboard.azure_network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_public_ip_icon
  color = "purple"
  fold {
    title     = "Public IPs"
    icon      = local.azure_public_ip_icon
    threshold = 3
  }
}

category "azure_route_table" {
  icon = local.azure_route_table_icon
  fold {
    title     = "Route Tables"
    icon      = local.azure_route_table_icon
    threshold = 3
  }
}

category "azure_sql_database" {
  href = "/azure_insights.dashboard.azure_sql_database_detail?input.database_id={{.properties.'ID' | @uri}}"
  icon = local.azure_sql_database_icon
  fold {
    title     = "SQL Databases"
    icon      = local.azure_sql_database_icon
    threshold = 3
  }
}

category "azure_sql_server" {
  href = "/azure_insights.dashboard.azure_sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon = local.azure_sql_server_icon
  fold {
    title     = "SQL Servers"
    icon      = local.azure_sql_server_icon
    threshold = 3
  }
}

category "azure_sql_server_audit_policy" {
  fold {
    title     = "SQL Server Audit Policies"
    threshold = 3
  }
}

category "azure_sql_server_firewall" {
  fold {
    title     = "SQL Server Firewalls"
    threshold = 3
  }
}

category "azure_private_endpoint_connection" {
  icon = local.azure_private_endpoint_connection_icon
  fold {
    title     = "Private Endpoint Connections"
    icon      = local.azure_private_endpoint_connection_icon
    threshold = 3
  }
}

category "azure_servicebus_namespace" {
  fold {
    title     = "Servicebus Namespaces"
    threshold = 3
  }
}

category "azure_storage_account" {
  href = "/azure_insights.dashboard.azure_storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon = local.azure_storage_account_icon
  fold {
    title     = "Storage Accounts"
    icon      = local.azure_storage_account_icon
    threshold = 3
  }
}

category "azure_storage_blob" {
  fold {
    title     = "Storage Blobs"
    threshold = 3
  }
}

category "azure_storage_container" {
  icon = local.azure_storage_container_icon
  fold {
    title     = "Storage Containers"
    icon      = local.azure_storage_container_icon
    threshold = 3
  }
}

category "azure_storage_queue" {
  icon = local.azure_storage_queue_icon
  fold {
    title     = "Storage Queues"
    icon      = local.azure_storage_queue_icon
    threshold = 3
  }
}

category "azure_storage_table" {
  fold {
    title     = "Storage Tables"
    threshold = 3
  }
}

category "azure_subnet" {
  href  = "/azure_insights.dashboard.azure_network_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-solid:share"
  color = "purple"
  fold {
    title     = "Subnets"
    icon      = "heroicons-solid:share"
    threshold = 3
  }
}

category "azure_virtual_network" {
  href  = "/azure_insights.dashboard.azure_virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:cloud"
  color = "purple"
  fold {
    title     = "Virtual Networks"
    icon      = "heroicons-outline:cloud"
    threshold = 3
  }
}

category "azure_mssql_elasticpool" {
  icon = local.azure_mssql_elasticpool_icon
  fold {
    title     = "SQL Elastic Pools"
    icon      = local.azure_mssql_elasticpool_icon
    threshold = 3
  }
}

category "azure_compute_disk_encryption_set" {
  icon  = local.azure_compute_disk_encryption_set_icon
  color = "green"
  fold {
    title     = "Compute Disk Encryption Sets"
    icon      = local.azure_compute_disk_encryption_set_icon
    threshold = 3
  }
}

category "azure_network_watcher_flow_log" {
  fold {
    title     = "Network Watcher Flow Logs"
    threshold = 3
  }
}

category "azure_compute_virtual_machine_scale_set" {
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:square-2-stack"
  color = "orange"
  fold {
    title     = "Compute Virtual Machine Scale Set"
    icon      = "heroicons-outline:square-2-stack"
    threshold = 3
  }
}

category "azure_lb" {
  href  = "/azure_insights.dashboard.azure_network_load_balancer_detail?input.lb_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_lb_icon
  color = "purple"
  fold {
    title     = "Load Balancers"
    icon      = local.azure_lb_icon
    threshold = 3
  }
}

category "azure_lb_backend_address_pool" {
  icon  = "text:BAP"
  color = "purple"
  fold {
    title     = "Backend Address Pools"
    threshold = 3
  }
}

category "azure_lb_rule" {
  fold {
    title     = "Load Balancer Rules"
    threshold = 3
  }
}

category "azure_lb_probe" {

  fold {
    title     = "Probes"
    threshold = 3
  }
}

category "azure_lb_nat_rule" {

  fold {
    title     = "NAT Rules"
    threshold = 3
  }
}

category "azure_firewall" {
  fold {
    title     = "Firewall"
    threshold = 3
  }
}

category "azure_nat_gateway" {
  icon = local.azure_nat_gateway_icon
  fold {
    title     = "NAT Gateway"
    icon      = local.azure_nat_gateway_icon
    threshold = 3
  }
}

category "azure_storage_share_file" {
  fold {
    title     = "Share Files"
    threshold = 3
  }
}

category "azure_compute_disk_access" {
  fold {
    title     = "Compute Disk Accesses"
    threshold = 3
  }
}

category "azure_compute_virtual_machine_scale_set_vm" {
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_compute_virtual_machine_icon
  color = "orange"
  fold {
    title     = "Compute Virtual Machine Scale Set VMs"
    icon      = local.azure_compute_virtual_machine_icon
    threshold = 3
  }
}

category "azure_compute_virtual_machine_scale_set_network_interface" {
  icon  = local.azure_network_interface_icon
  color = "purple"
  fold {
    title     = "Compute Virtual Machine Scale Set Network Interfaces"
    icon      = local.azure_network_interface_icon
    threshold = 3
  }
}
