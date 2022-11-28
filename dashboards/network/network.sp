locals {
  network_common_tags = {
    service = "Azure/Network"
  }
}

category "azure_application_gateway" {
  title = "Application Gateway"
  icon  = "arrows-pointing-out"
  color = local.network_color
}

category "azure_firewall" {
  title = "Firewall"
  icon  = "fire"
  color = local.network_color
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

category "azure_lb_nat_rule" {
  title = "Load Balancer NAT Rule"
  icon  = "text:LBNatRule"
  color = local.network_color
}

category "azure_lb_probe" {
  title = "Load Balancer Probe"
  icon  = "text:LBProbe"
  color = local.network_color
}

category "azure_lb_rule" {
  title = "Load Balancer Rule"
  icon  = "text:LBRule"
  color = local.network_color
}

category "azure_nat_gateway" {
  title = "NAT Gateway"
  icon  = "text:LBNatGateway"
  color = local.network_color
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

category "azure_network_watcher_flow_log" {
  title = "Network Watcher Flow Log"
  icon  = "text:NWFlowLog"
  color = local.network_color
}

category "azure_public_ip" {
  title = "Public IP"
  href  = "/azure_insights.dashboard.azure_network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = "text:EIP"
  color = local.network_color
}

category "azure_private_endpoint_connection" {
  title = "Private Endpoint Connection"
  icon  = "text:PEC"
  color = local.network_color
}

category "azure_route_table" {
  title = "Route Table"
  icon  = "arrows-right-left"
  color = local.network_color
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