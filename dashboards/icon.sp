locals {
  azure_app_service_web_app_icon         = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/app_service_web_app.svg"))
  azure_application_gateway_icon         = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/application_gateway.svg"))
  azure_compute_disk_encryption_set_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_disk_encryption_set.svg"))
  azure_compute_disk_icon                = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_disk.svg"))
  azure_compute_snapshot_icon            = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_snapshot.svg"))
  azure_compute_virtual_machine_icon     = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_virtual_machine.svg"))
  azure_cosmosdb_account_icon            = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cosmosdb_account.svg"))
  azure_image_icon                       = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/image.svg"))
  azure_key_vault_firewall_icon          = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/azure_network_acl_light.svg"))
  azure_key_vault_icon                   = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/key_vault.svg"))
  azure_lb_icon                         = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/load_balancer.svg"))
  azure_manage_disk_icon                 = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/manage_disk.svg"))
  azure_mssql_elasticpool_icon           = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/mssql_elasticpool.svg"))
  azure_nat_gateway_icon                 = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/nat_gateway.svg"))
  azure_network_interface_icon           = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/network_interface.svg"))
  azure_network_security_group_icon      = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/network_security_group.svg"))
  azure_private_endpoint_connection_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/private_endpoint_connection.svg"))
  azure_public_ip_icon                   = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/public_ip.svg"))
  azure_route_table_icon                 = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/route_table.svg"))
  azure_security_profile_icon            = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/security_profile.svg"))
  azure_sql_database_icon                = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/sql_database.svg"))
  azure_sql_server_icon                  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/sql_server.svg"))
  azure_storage_account_icon             = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/storage_account.svg"))
  azure_storage_container_icon           = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/storage_container.svg"))
  azure_storage_queue_icon               = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/storage_queue.svg"))
  azure_virtual_network_icon             = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/virtual_network.svg"))
}
