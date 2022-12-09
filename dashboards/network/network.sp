locals {
  network_common_tags = {
    service = "Azure/Network"
  }
}

category "network_application_gateway" {
  title = "Application Gateway"
  icon  = "heroicons-outline:arrows-pointing-out"
  color = local.networking_color
}

category "network_firewall" {
  href  = "/azure_insights.dashboard.network_firewall_detail?input.firewall_id={{.properties.'ID' | @uri}}"
  title = "Firewall"
  icon  = "heroicons-outline:fire"
  color = local.networking_color
}

category "network_load_balancer" {
  title = "Load Balancer"
  href  = "/azure_insights.dashboard.network_load_balancer_detail?input.lb_id={{.properties.'ID' | @uri}}"
  icon  = "text:LB"
  color = local.networking_color
}

category "network_load_balancer_backend_address_pool" {
  title = "Backend Address Pool"
  icon  = "text:LBBackendAddressPool"
  color = local.networking_color
}

category "network_load_balancer_nat_rule" {
  title = "Load Balancer NAT Rule"
  icon  = "text:LBNatRule"
  color = local.networking_color
}

category "network_load_balancer_probe" {
  title = "Load Balancer Probe"
  icon  = "text:LBProbe"
  color = local.networking_color
}

category "network_load_balancer_rule" {
  title = "Load Balancer Rule"
  icon  = "text:LBRule"
  color = local.networking_color
}

category "network_nat_gateway" {
  title = "NAT Gateway"
  icon  = "text:LBNatGateway"
  color = local.networking_color
}

category "network_network_interface" {
  title = "Network Interface"
  href  = "/azure_insights.dashboard.network_interface_detail?input.nic_id={{.properties.'ID' | @uri}}"
  icon  = "text:ENI"
  color = local.networking_color
}

category "network_peering" {
  title = "Network Peering"
  icon  = "heroicons-outline:cube-transparent"
  color = local.networking_color
}

category "network_private_endpoint_connection" {
  title = "Private Endpoint Connection"
  icon  = "text:PEC"
  color = local.networking_color
}

category "network_public_ip" {
  title = "Public IP"
  href  = "/azure_insights.dashboard.network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = "text:EIP"
  color = local.networking_color
}

category "network_route_table" {
  title = "Route Table"
  icon  = "heroicons-outline:arrows-right-left"
  color = local.networking_color
}

category "network_security_group" {
  title = "Network Security Group"
  href  = "/azure_insights.dashboard.network_security_group_detail?input.nsg_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:lock-closed"
  color = local.networking_color
}

category "network_subnet" {
  title = "Subnet"
  href  = "/azure_insights.dashboard.network_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:share"
  color = local.networking_color
}

category "network_virtual_network" {
  title = "Virtual Network"
  href  = "/azure_insights.dashboard.virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:cloud"
  color = local.networking_color
}

category "network_watcher_flow_log" {
  title = "Network Watcher Flow Log"
  icon  = "text:NWFlowLog"
  color = local.networking_color
}
