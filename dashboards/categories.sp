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
  href  = "/azure_insights.dashboard.azure_app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  icon  = "text:web_app"
  color = "blue"
}

category "azure_app_service_plan" {
  title = "App Service Plan"
  icon  = "text:app_service_plan"
  color = "blue"
}

category "azure_container_registry" {
  title = "Container Registry"
  icon  = "text:container_registry"
  color = "orange"
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
  icon  = "magnifying-glass"
  color = "red"
}

category "azure_eventhub_namespace" {
  title = "EventHub Namespace"
  icon  = "text:eventHub_namespace"
  color = "purple"
}

category "azure_image" {
  title = "Compute Image"
  icon  = "text:compute_image"
  color = "orange"
}

category "azure_key_vault" {
  title = "Key Vault"
  href  = "/azure_insights.dashboard.azure_key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = "text:key_vault"
  color = "red"
}

category "azure_key_vault_firewall" {
  title = "Networking Firewall"
  icon  = "text:firewall"
  color = "red"
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
  href  = "/azure_insights.dashboard.azure_network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = "text:public_ip"
  color = "purple"
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
  title = "Private Endpoint Connection"
  icon  = "text:private-ep"
  color = "purple"
}

category "azure_servicebus_namespace" {
  title = "Servicebus Namespace"
  icon  = "text:servicebus-ns"
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
  icon  = "text:storage-blob"
  color = "green"
}

category "azure_storage_container" {
  title = "Storage Container"
  icon  = "text:storage-container"
  color = "green"
}

category "azure_storage_queue" {
  title = "Storage Queue"
  icon  = "text:storage-queue"
  color = "green"
}

category "azure_storage_table" {
  title = "Storage Table"
  icon  = "text:storage-table"
  color = "green"
}

category "azure_subnet" {
  title = "Subnet"
  href  = "/azure_insights.dashboard.azure_network_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  icon  = "share"
  color = "purple"
}

category "azure_virtual_network" {
  title = "Virtual Network"
  href  = "/azure_insights.dashboard.azure_virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "cloud"
  color = "purple"
}

category "azure_mssql_elasticpool" {
  title = "SQL Elastic Pool"
  icon  = "text:mssql-elastic-pool"
  color = "purple"
}

category "azure_compute_disk_encryption_set" {
  title = "Compute Disk Encryption Set"
  icon  = "text:disk-encryp-set"
  color = "green"
}

category "azure_network_watcher_flow_log" {
  title = "Network Watcher Flow Log"
  icon  = "text:nw-flow-log"
  color = "deeppink"
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
  icon  = "text:backend_address_pool"
  color = "purple"
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
  icon  = "text:nat_rule"
  color = "purple"
}

category "azure_firewall" {
  title = "Firewall"
  icon  = "fire"
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