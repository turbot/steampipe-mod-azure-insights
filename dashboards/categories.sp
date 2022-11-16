category "azure_api_management" {
  title = "API Management"
  icon  = "bolt"
  color = "red"
}

category "azure_application_gateway" {
  title = "Application Gateway"
  icon  = "text:app_gateway"
  color = "purple"
}

category "azure_app_service_web_app" {
  title = "Web App"
  icon  = "text:web_app"
  href  = "/azure_insights.dashboard.azure_app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  color = "blue"
}

category "azure_app_service_plan" {
  title = "App Service Plan"
  icon  = "text:app_service_plan"
  color = "blue"
}

category "azure_container_registry" {
  title = "Container Registry"
  color = "orange"
  icon  = "text:container_registry"
}

category "azure_compute_disk" {
  title = "Compute Disk"
  href  = "/azure_insights.dashboard.azure_compute_disk_detail?input.d_id={{.properties.'ID' | @uri}}"
  icon  = "inbox-stack"
  color = "green"
}

category "azure_compute_snapshot" {
  title = "Compute Snapshot"
  href  = "/azure_insights.dashboard.azure_compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon  = "viewfinder-circle"
  color = "green"
}

category "azure_compute_virtual_machine" {
  title = "Virtual Machine"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = "orange"
}

category "azure_cosmosdb_account" {
  title = "Cosmos DB Account"
  icon  = "circle-stack"
  color = "blue"
}

category "azure_diagnostic_setting" {
  title = "Diagnostic Setting"
  color = "red"
  icon  = "magnifying-glass"
}

category "azure_eventhub_namespace" {
  title = "EventHub Namespace"
  icon  = "text:eventHub_namespace"
  color = "purple"
}

category "azure_image" {
  title = "Compute Image"
  color = "orange"
  icon  = "text:compute_image"
}

category "azure_key_vault" {
  title = "Key Vault"
  href  = "/azure_insights.dashboard.azure_key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = "text:key_vault"
  color = "red"
}

category "azure_key_vault_firewall" {
  color = "red"
  title = "Networking Firewall"
  icon  = "text:firewall"
}

category "azure_key_vault_key" {
  title = "Key Vault Key"
  icon  = "key"
  color = "red"
}

category "azure_key_vault_secret" {
  title = "Key Vault Secret"
  icon  = "text:secret"
  color = "red"
}

category "azure_log_profile" {
  title = "Log Profile"
  icon  = "text:log_profile"
  color = "deeppink"
}

category "azure_network_interface" {
  title = "Network Interface"
  href  = "/azure_insights.dashboard.azure_network_interface_detail?input.nic_id={{.properties.'ID' | @uri}}"
  icon  = "text:eni"
  color = "purple"
}

category "azure_network_peering" {
  title = "Network Peering"
  icon  = "cube-transparent"
  color = "purple"
}

category "azure_network_security_group" {
  title = "Network Security Group"
  href  = "/azure_insights.dashboard.azure_network_security_group_detail?input.nsg_id={{.properties.'ID' | @uri}}"
  icon  = "lock-closed"
  color = "purple"
}

category "azure_postgresql_server" {
  title = "Postgresql Server"
  icon  = "text:postgresql_server"
  color = "blue"
}

category "azure_public_ip" {
  title = "Public IP"
  color = "purple"
  href  = "/azure_insights.dashboard.azure_network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = "text:public_ip"
}

category "azure_route_table" {
  title = "Route Table"
  icon  = "arrows-right-left"
  color = "purple"
}

category "azure_sql_database" {
  title = "SQL Database"
  href  = "/azure_insights.dashboard.azure_sql_database_detail?input.database_id={{.properties.'ID' | @uri}}"
  icon  = "text:sql_database"
  color = "blue"
}

category "azure_sql_server" {
  title = "SQL Server"
  href  = "/azure_insights.dashboard.azure_sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon  = "circle-stack"
  color = "blue"
}

category "azure_private_endpoint_connection" {
  icon  = local.azure_private_endpoint_connection_icon
  title = "Private Endpoint Connection"
  color = "purple"
}

category "azure_servicebus_namespace" {
  title = "Servicebus Namespace"
  color = "purple"
}

category "azure_storage_account" {
  title = "Storage Account"
  href  = "/azure_insights.dashboard.azure_storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = "archive-box"
  color = "green"
}

category "azure_storage_blob" {
  title = "Storage Blob"
  color = "green"
}

category "azure_storage_container" {
  icon  = local.azure_storage_container_icon
  title = "Storage Container"
  color = "green"
}

category "azure_storage_queue" {
  icon  = local.azure_storage_queue_icon
  title = "Storage Queue"
  color = "green"
}

category "azure_storage_table" {
  title = "Storage Table"
  color = "green"
}

category "azure_subnet" {
  title = "Subnet"
  href  = "/azure_insights.dashboard.azure_network_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-solid:share"
  color = "purple"
}

category "azure_virtual_network" {
  title = "Virtual Network"
  href  = "/azure_insights.dashboard.azure_virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "cloud" //"text:vpc"
  color = "purple"
}

category "azure_mssql_elasticpool" {
  title = "SQL Elastic Pool"
  icon  = local.azure_mssql_elasticpool_icon
  color = "purple"
}

category "azure_compute_disk_encryption_set" {
  title = "Compute Disk Encryption Set"
  icon  = local.azure_compute_disk_encryption_set_icon
  color = "green"
}

category "azure_network_watcher_flow_log" {
  title = "Network Watcher Flow Log"
  color = "deeppink"
  icon  = "text:nw-flow-log"
}

category "azure_compute_virtual_machine_scale_set" {
  title = "Compute Virtual Machine Scale Set"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon  = "rectangle-stack"
  color = "purple"
}

category "azure_lb" {
  title = "Load Balancer"
  href  = "/azure_insights.dashboard.azure_network_load_balancer_detail?input.lb_id={{.properties.'ID' | @uri}}"
  icon  = "text:lb"
  color = "purple"
}

category "azure_lb_backend_address_pool" {
  title = "Backend Address Pool"
  color = "purple"
  icon  = "text:backend_address_pool"
}

category "azure_lb_rule" {
  title = "Load Balancer Rule"
  icon  = "text:lb_rule"
  color = "purple"
}

category "azure_lb_probe" {
  title = "Probe"
  icon  = "text:lb_probe"
  color = "purple"
}

category "azure_lb_nat_rule" {
  title = "NAT Rule"
  color = "purple"
  icon  = "text:nat_rule"
}

category "azure_firewall" {
  title = "Firewall"
  icon  = "text:fire"
  color = "red"
}

category "azure_nat_gateway" {
  title = "NAT Gateway"
  icon  = "text:nat_gateway"
  color = "purple"
}

category "azure_storage_share_file" {
  title = "Share File"
  icon  = "text:share_file"
  color = "green"
}

category "azure_compute_disk_access" {
  title = "Compute Disk Access"
  icon  = "text:disk_acces"
  color = "green"
}

category "azure_compute_virtual_machine_scale_set_vm" {
  title = "Compute Virtual Machine Scale Set VM"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = "purple"
}

category "azure_compute_virtual_machine_scale_set_network_interface" {
  title = "Compute Virtual Machine Scale Set Network Interface"
  icon  = "text:eni"
  color = "purple"
}
