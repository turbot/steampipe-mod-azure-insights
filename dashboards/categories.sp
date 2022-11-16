category "azure_api_management" {
  icon  = "bolt"
  color = "red"

  fold {
    icon      = "bolt"
    title     = "API Management"
    threshold = 3
  }
}

category "azure_application_gateway" {
  icon  = "text:app_gateway"
  color = "purple"
  fold {
    title     = "Application Gateways"
    icon      = "text:app_gateway"
    threshold = 3
  }
}

category "azure_app_service_web_app" {
  icon  = "text:web_app"
  href  = "/azure_insights.dashboard.azure_app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  color = "orange"
  fold {
    title     = "Web Apps"
    icon      = "text:web_app"
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
  icon  = "inbox-stack"
  color = "green"
  fold {
    title     = "Compute Disks"
    icon      = "inbox-stack"
    threshold = 3
  }
}

category "azure_compute_snapshot" {
  href = "/azure_insights.dashboard.azure_compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon = local.azure_compute_snapshot_icon
  fold {
    title     = "Compute Snapshots"
    icon      = local.azure_compute_snapshot_icon
    threshold = 3
  }
}

category "azure_compute_virtual_machine" {
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = "orange"

  fold {
    title     = "Virtual Machine"
    icon      = "cpu-chip"
    threshold = 3
  }
}

category "azure_cosmosdb_account" {
  icon  = "circle-stack"
  color = "blue"
  fold {
    title     = "Cosmos DB Accounts"
    icon      = "text:cosmosdb"
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
  color = "orange"
  icon  = local.azure_image_icon
  fold {
    title     = "Compute Images"
    icon      = local.azure_image_icon
    threshold = 3
  }
}

category "azure_key_vault" {
  href  = "/azure_insights.dashboard.azure_key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = "key"
  color = "red"

  fold {
    title     = "Key Vaults"
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
  icon  = "key"
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
  icon  = "text:network-interface"
  color = "purple"
  fold {
    title     = "Network Interfaces"
    icon      = "text:network-interface"
    threshold = 3
  }
}

category "azure_network_peering" {
  icon  = "text:network-peering"
  color = "purple"
  fold {
    title     = "Network Peering"
    icon      = "text:network-peering"
    threshold = 3
  }
}

category "azure_network_security_group" {
  href  = "/azure_insights.dashboard.azure_network_security_group_detail?input.nsg_id={{.properties.'ID' | @uri}}"
  icon  = "lock-closed"
  color = "purple"

  fold {
    icon      = "lock-closed"
    title     = "Network Security Groups"
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
  color = "purple"
  href  = "/azure_insights.dashboard.azure_network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_public_ip_icon
  fold {
    title     = "Public IPs"
    icon      = local.azure_public_ip_icon
    threshold = 3
  }
}

category "azure_route_table" {
  icon  = "arrows-right-left"
  color = "purple"
  fold {
    title     = "Route Tables"
    icon      = "arrows-right-left"
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
  href  = "/azure_insights.dashboard.azure_sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon  = "circle-stack"
  color = "blue"
  fold {
    title     = "SQL Servers"
    icon      = "circle-stack"
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
  href  = "/azure_insights.dashboard.azure_storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = "archive-box"
  color = "green"

  fold {
    title     = "Storage Accounts"
    icon      = "archive-box"
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
    icon = "heroicons-solid:share"
    // color = "purple"
    title     = "Subnets"
    threshold = 3
  }
}

category "azure_virtual_network" {
  href  = "/azure_insights.dashboard.azure_virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "cloud" //"text:vpc"
  color = "purple"

  fold {
    icon      = "cloud" //"text:vpc"
    title     = "Virtual Networks"
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
  icon  = "inbox-stack"
  color = "green"
  fold {
    title     = "Compute Disk Encryption Sets"
    icon      = "inbox-stack"
    threshold = 3
  }
}

category "azure_network_watcher_flow_log" {
  color = "deeppink"
  icon  = "text:nw-flow-log"
  fold {
    title     = "Network Watcher Flow Logs"
    icon      = "text:nw-flow-log"
    threshold = 3
  }
}

category "azure_compute_virtual_machine_scale_set" {
  href = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon = local.azure_compute_virtual_machine_scale_set_icon
  fold {
    title     = "Compute Virtual Machine Scale Set"
    icon      = local.azure_compute_virtual_machine_scale_set_icon
    threshold = 3
  }
}

category "azure_lb" {
  href = "/azure_insights.dashboard.azure_network_load_balancer_detail?input.lb_id={{.properties.'ID' | @uri}}"
  icon = local.azure_lb_icon
  fold {
    title     = "Load Balancers"
    icon      = local.azure_lb_icon
    threshold = 3
  }
}

category "azure_lb_backend_address_pool" {
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
  icon  = "text:nat_gateway"
  color = "purple"

  fold {
    title     = "NAT Gateway"
    icon      = "text:nat_gateway"
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
  icon = "inbox-stack"
  fold {
    title     = "Compute Disk Accesses"
    icon      = "inbox-stack"
    threshold = 3
  }
}

category "azure_compute_virtual_machine_scale_set_vm" {
  href = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon = local.azure_compute_virtual_machine_icon
  fold {
    title     = "Compute Virtual Machine Scale Set VMs"
    icon      = local.azure_compute_virtual_machine_icon
    threshold = 3
  }
}

category "azure_compute_virtual_machine_scale_set_network_interface" {
  icon = local.azure_network_interface_icon
  fold {
    title     = "Compute Virtual Machine Scale Set Network Interfaces"
    icon      = local.azure_network_interface_icon
    threshold = 3
  }
}
