category "azure_api_management" {
  title = "API Management"
  icon  = "bolt"
  color = local.front_end_web
}

category "azure_application_gateway" {
  title = "Application Gateway"
  icon  = "arrows-pointing-out"
  color = local.network_color
}

category "azure_app_service_web_app" {
  title = "App Service Web App"
  href  = "/azure_insights.dashboard.azure_app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  icon  = "text:WA"
  color = local.storage_color
}

category "azure_app_service_plan" {
  title = "App Service Plan"
  icon  = "text:ASP"
  color = local.storage_color
}

category "azure_container_registry" {
  title = "Container Registry"
  icon  = "text:CR"
  color = local.container_color
}

category "azure_compute_disk" {
  title = "Compute Disk"
  href  = "/azure_insights.dashboard.azure_compute_disk_detail?input.d_id={{.properties.'ID' | @uri}}"
  icon  = "inbox-stack"
  color = local.storage_color
}

category "azure_compute_snapshot" {
  title = "Compute Snapshot"
  href  = "/azure_insights.dashboard.azure_compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon  = "viewfinder-circle"
  color = local.storage_color
}

category "azure_compute_virtual_machine" {
  title = "Compute Virtual Machine"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = local.compute_color
}

category "azure_cosmosdb_account" {
  title = "Cosmos DB Account"
  icon  = "circle-stack"
  color = local.database_color
}

category "azure_diagnostic_setting" {
  title = "Diagnostic Setting"
  icon  = "magnifying-glass"
  color = local.management_governance_color
}

category "azure_eventhub_namespace" {
  title = "EventHub Namespace"
  icon  = "text:EN"
  color = local.analytics_color
}

category "azure_compute_image" {
  title = "Compute Image"
  icon  = "text:Image"
  color = local.compute_color
}

category "azure_key_vault" {
  title = "Key Vault"
  href  = "/azure_insights.dashboard.azure_key_vault_detail?input.key_vault_id={{.properties.'ID' | @uri}}"
  icon  = "text:KV"
  color = local.security_color
}

category "azure_key_vault_key" {
   href  = "/azure_insights.dashboard.azure_key_vault_key_detail?input.key_vault_key_id={{.properties.'Key ID' | @uri}}"
  title = "Key Vault Key"
  icon  = "key"
  color = local.security_color
}

category "azure_key_vault_secret" {
  title = "Key Vault Secret"
  icon  = "text:Secret"
  color = local.security_color
}

category "azure_log_profile" {
  title = "Log Profile"
  icon  = "text:LP"
  color = local.management_governance_color
}

category "azure_network_interface" {
  title = "Network Interface"
  href  = "/azure_insights.dashboard.azure_network_interface_detail?input.nic_id={{.properties.'ID' | @uri}}"
  icon  = "text:ENI"
  color = local.network_color
}

category "azure_network_peering" {
  title = "Network Peering"
  icon  = "cube-transparent"
  color = local.network_color
}

category "azure_network_security_group" {
  title = "Network Security Group"
  href  = "/azure_insights.dashboard.azure_network_security_group_detail?input.nsg_id={{.properties.'ID' | @uri}}"
  icon  = "lock-closed"
  color = local.network_color
}

category "azure_postgresql_server" {
  title = "Postgresql Server"
  icon  = "circle-stack"
  color = local.database_color
}

category "azure_public_ip" {
  title = "Public IP"
  href  = "/azure_insights.dashboard.azure_network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = "text:EIP"
  color = local.network_color
}

category "azure_route_table" {
  title = "Route Table"
  icon  = "arrows-right-left"
  color = local.network_color
}

category "azure_sql_database" {
  title = "SQL Database"
  href  = "/azure_insights.dashboard.azure_sql_database_detail?input.database_id={{.properties.'ID' | @uri}}"
  icon  = "circle-stack"
  color = local.database_color
}

category "azure_sql_server" {
  title = "SQL Server"
  href  = "/azure_insights.dashboard.azure_sql_server_detail?input.server_id={{.properties.'ID' | @uri}}"
  icon  = "circle-stack"
  color = local.database_color
}

category "azure_private_endpoint_connection" {
  title = "Private Endpoint Connection"
  icon  = "text:PEC"
  color = local.network_color
}

category "azure_servicebus_namespace" {
  title = "Servicebus Namespace"
  icon  = "text:SN"
  color = local.integration_color
}

category "azure_storage_account" {
  title = "Storage Account"
  href  = "/azure_insights.dashboard.azure_storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = "archive-box"
  color = local.storage_color
}

category "azure_storage_blob" {
  title = "Storage Blob"
  icon  = "text:StorageBlob"
  color = local.storage_color
}

category "azure_storage_container" {
  title = "Storage Container"
  icon  = "text:StorageContainer"
  color = local.storage_color
}

category "azure_storage_queue" {
  title = "Storage Queue"
  icon  = "text:StorageQueue"
  color = local.storage_color
}

category "azure_storage_table" {
  title = "Storage Table"
  icon  = "text:StorageTable"
  color = local.storage_color
}

category "azure_subnet" {
  title = "Subnet"
  href  = "/azure_insights.dashboard.azure_network_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  icon  = "share"
  color = local.network_color
}

category "azure_virtual_network" {
  title = "Virtual Network"
  href  = "/azure_insights.dashboard.azure_virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "cloud"
  color = local.network_color
}

category "azure_mssql_elasticpool" {
  title = "SQL Elastic Pool"
  icon  = "text:ElasticPool"
  color = local.database_color
}

category "azure_compute_disk_encryption_set" {
  title = "Compute Disk Encryption Set"
  icon  = "text:DES"
  color = local.security_color
}

category "azure_network_watcher_flow_log" {
  title = "Network Watcher Flow Log"
  icon  = "text:NWFlowLog"
  color = local.network_color
}

category "azure_compute_virtual_machine_scale_set" {
  title = "Compute Virtual Machine Scale Set"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon  = "square-2-stack"
  color = local.compute_color
}

category "azure_lb" {
  title = "Load Balancer"
  href  = "/azure_insights.dashboard.azure_network_load_balancer_detail?input.lb_id={{.properties.'ID' | @uri}}"
  icon  = "text:LB"
  color = local.network_color
}

category "azure_lb_backend_address_pool" {
  title = "Backend Address Pool"
  icon  = "text:LBBackendAddressPool"
  color = local.network_color
}

category "azure_lb_rule" {
  title = "Load Balancer Rule"
  icon  = "text:LBRule"
  color = local.network_color
}

category "azure_lb_probe" {
  title = "Load Balancer Probe"
  icon  = "text:LBProbe"
  color = local.network_color
}

category "azure_lb_nat_rule" {
  title = "Load Balancer NAT Rule"
  icon  = "text:LBNatRule"
  color = local.network_color
}

category "azure_firewall" {
  title = "Firewall"
  icon  = "fire"
  color = local.network_color
}

category "azure_nat_gateway" {
  title = "NAT Gateway"
  icon  = "text:LBNatGateway"
  color = local.network_color
}

category "azure_storage_share_file" {
  title = "Storage Share File"
  icon  = "text:StorageShareFile"
  color = local.storage_color
}

category "azure_compute_disk_access" {
  title = "Compute Disk Access"
  icon  = "text:DiskAccess"
  color = local.storage_color
}

category "azure_compute_virtual_machine_scale_set_vm" {
  title = "Compute Virtual Machine Scale Set VM"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = local.compute_color
}

category "azure_compute_virtual_machine_scale_set_network_interface" {
  title = "Compute Virtual Machine Scale Set Network Interface"
  icon  = "text:eni"
  color = local.network_color
}

category "azure_kubernetes_cluster" {
  title = "Kubernetes Clusters"
  href = "/azure_insights.dashboard.azure_kubernetes_cluster_detail?input.cluster_id={{.properties.'ID' | @uri}}"
  icon = "cog"
  color = local.container_color
}

category "azure_kubernetes_node_pool" {
  title = "Kubernetes Node Pools"
  icon  = "text:NodePool"
  color = local.container_color
}

category "azure_key_vault_key_verison" {
  title = "Key Version"
  icon  = "key"
  color = local.security_color
}

category "azure_batch_account" {
  title = "Batch Account"
  icon  = "text:BatchAccount"
  color = local.compute_color
}
