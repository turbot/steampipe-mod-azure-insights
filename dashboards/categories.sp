category "azure_api_management" {
  title = "API Management"
}

category "azure_application_gateway" {
  // icon  = local.azure_application_gateway_icon
  icon  = "text:App Gateway"
  color = "purple"
  title = "Application Gateway"
}

category "azure_app_service_web_app" {
  icon  = local.azure_app_service_web_app_icon
  href  = "/azure_insights.dashboard.azure_app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  title = "Web App"
}

category "azure_app_service_plan" {
  icon  = "text:web-app"
  title = "App Service Plan"
}

category "azure_container_registry" {
  title = "Container Registry"
}

category "azure_compute_disk" {
  href  = "/azure_insights.dashboard.azure_compute_disk_detail?input.d_id={{.properties.'ID' | @uri}}"
  icon  = "inbox-stack"
  color = "green"
  title = "Compute Disk"
}

category "azure_compute_snapshot" {
  href  = "/azure_insights.dashboard.azure_compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon  = "viewfinder-circle"
  color = "green"
  title = "Compute Snapshot"
}

category "azure_compute_virtual_machine" {
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_compute_virtual_machine_icon
  color = "orange"
  title = "Compute Virtual Machine"
}

category "azure_cosmosdb_account" {
  icon  = local.azure_cosmosdb_account_icon
  title = "Cosmos DB Account"
}

category "azure_diagnostic_setting" {
  title = "Diagnostic Setting"
}

category "azure_eventhub_namespace" {
  title = "EventHub Namespace"
  color = "purple"
}

category "azure_image" {
  icon  = local.azure_image_icon
  title = "Compute Image"
}

category "azure_key_vault" {
  href  = "/azure_insights.dashboard.azure_key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_key_vault_icon
  color = "red"
  title = "Key Vault"
}

category "azure_key_vault_firewall" {
  icon  = local.azure_key_vault_firewall_icon
  title = "Networking Firewall"
}

category "azure_key_vault_key" {
  icon  = local.azure_key_vault_key_icon
  color = "red"
  title = "Key"
}

category "azure_key_vault_secret" {
  title = "Secret"
}

category "azure_log_profile" {
  title = "Log Profile"
}

category "azure_network_interface" {
  href  = "/azure_insights.dashboard.azure_network_interface_detail?input.nic_id={{.properties.'ID' | @uri}}"
  icon  = "text:nic"
  color = "purple"
  title = "Network Interface"
}

category "azure_network_security_group" {
  href  = "/azure_insights.dashboard.azure_network_security_group_detail?input.nsg_id={{.properties.'ID' | @uri}}"
  icon  = "lock-closed"
  color = "purple"
  title = "Network Security Group"
}

category "azure_postgresql_server" {
  title = "Postgresql Server"
}

category "azure_public_ip" {
  href = "/azure_insights.dashboard.azure_network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  // icon  = local.azure_public_ip_icon
  icon  = "text:public ip"
  color = "purple"
  title = "Public IP"
}

category "azure_route_table" {
  icon  = local.azure_route_table_icon
  title = "Route Table"
}

category "azure_sql_database" {
  href  = "/azure_insights.dashboard.azure_sql_database_detail?input.database_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_sql_database_icon
  title = "SQL Database"
}

category "azure_sql_server" {
  href  = "/azure_insights.dashboard.azure_sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_sql_server_icon
  title = "SQL Server"
}

category "azure_sql_server_audit_policy" {
  title = "SQL Server Audit Policy"
}

category "azure_sql_server_firewall" {
  title = "SQL Server Firewall"
}

category "azure_private_endpoint_connection" {
  icon  = local.azure_private_endpoint_connection_icon
  title = "Private Endpoint Connection"
}

category "azure_servicebus_namespace" {
  title = "Servicebus Namespace"
}

category "azure_storage_account" {
  href  = "/azure_insights.dashboard.azure_storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = local.azure_storage_account_icon
  title = "Storage Account"
}

category "azure_storage_blob" {
  title = "Storage Blob"
}

category "azure_storage_container" {
  icon  = local.azure_storage_container_icon
  title = "Storage Container"
}

category "azure_storage_queue" {
  icon  = local.azure_storage_queue_icon
  title = "Storage Queue"
}

category "azure_storage_table" {
  title = "Storage Table"
}

category "azure_subnet" {
  href  = "/azure_insights.dashboard.azure_network_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  icon  = "share"
  color = "purple"
  title = "Subnet"
}

category "azure_virtual_network" {
  href  = "/azure_insights.dashboard.azure_virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "cloud"
  color = "purple"
  title = "Virtual Network"
}

category "azure_mssql_elasticpool" {
  icon  = local.azure_mssql_elasticpool_icon
  title = "SQL Elastic Pool"
}

category "azure_compute_disk_encryption_set" {
  icon  = local.azure_compute_disk_encryption_set_icon
  color = "green"
  title = "Compute Disk Encryption Set"
}

category "azure_network_watcher_flow_log" {
  title = "Network Watcher Flow Log"
}

category "azure_compute_virtual_machine_scale_set" {
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon  = "square-2-stack"
  color = "orange"
  title = "Compute Virtual Machine Scale Set"
}

category "azure_lb" {
  href = "/azure_insights.dashboard.azure_network_load_balancer_detail?input.lb_id={{.properties.'ID' | @uri}}"
  // icon  = local.azure_lb_icon
  icon  = "text:lb"
  color = "purple"
  title = "Load Balancer"
}

category "azure_lb_backend_address_pool" {
  icon  = "text:BAP"
  color = "purple"
  title = "Backend Address Pool"
}

category "azure_lb_rule" {
  icon  = "text:lb rule"
  color = "purple"
  title = "Load Balancer Rule"
}

category "azure_lb_probe" {
  icon = "text:probe"
  color = "purple"
  title = "Probe"
}

category "azure_lb_nat_rule" {
  title = "NAT Rule"
  icon  = "text:nat rule"
  color = "purple"
}

category "azure_firewall" {
  title = "Firewall"
  icon  = "fire"
  color = "red"
}

category "azure_nat_gateway" {
  icon  = local.azure_nat_gateway_icon
  title = "NAT Gateway"
}

category "azure_storage_share_file" {
  title = "Share File"
}

category "azure_compute_disk_access" {
  title = "Compute Disk Access"
}

category "azure_compute_virtual_machine_scale_set_vm" {
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = "orange"
  title = "Compute Virtual Machine Scale Set VM"
}

category "azure_compute_virtual_machine_scale_set_network_interface" {
  icon  = "text:nic"
  color = "purple"
  title = "Compute Virtual Machine Scale Set Network Interface"
}
