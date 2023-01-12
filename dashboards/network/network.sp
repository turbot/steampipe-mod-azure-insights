locals {
  network_common_tags = {
    service = "Azure/Network"
  }
}

category "network_application_gateway" {
  title = "Application Gateway"
  color = local.networking_color
  icon  = "mediation"
}

category "network_firewall" {
  title = "Firewall"
  color = local.networking_color
  href  = "/azure_insights.dashboard.network_firewall_detail?input.firewall_id={{.properties.'ID' | @uri}}"
  icon  = "local_fire_department"
}

category "network_load_balancer" {
  title = "Load Balancer"
  color = local.networking_color
  href  = "/azure_insights.dashboard.network_load_balancer_detail?input.lb_id={{.properties.'ID' | @uri}}"
  icon  = "mediation"
}

category "network_load_balancer_backend_address_pool" {
  title = "Backend Address Pool"
  color = local.networking_color
  icon  = "directions"
}

category "network_load_balancer_nat_rule" {
  title = "Load Balancer NAT Rule"
  color = local.networking_color
  icon  = "rule"
}

category "network_load_balancer_probe" {
  title = "Load Balancer Probe"
  color = local.networking_color
  icon  = "usb"
}

category "network_load_balancer_rule" {
  title = "Load Balancer Rule"
  color = local.networking_color
  icon  = "description"
}

category "network_nat_gateway" {
  title = "NAT Gateway"
  color = local.networking_color
  icon  = "merge"
}

category "network_network_interface" {
  title = "Network Interface"
  color = local.networking_color
  href  = "/azure_insights.dashboard.network_interface_detail?input.nic_id={{.properties.'ID' | @uri}}"
  icon  = "settings_input_antenna"
}

category "network_peering" {
  title = "Network Peering"
  color = local.networking_color
  icon  = "sync_alt"
}

category "network_private_endpoint_connection" {
  title = "Private Endpoint Connection"
  color = local.networking_color
  icon  = "matter"
}

category "network_public_ip" {
  title = "Public IP"
  color = local.networking_color
  href  = "/azure_insights.dashboard.network_public_ip_detail?input.public_ip_id={{.properties.'ID' | @uri}}"
  icon  = "swipe_right_alt"
}

category "network_route_table" {
  title = "Route Table"
  color = local.networking_color
  icon  = "table_rows"
}

category "network_security_group" {
  title = "Network Security Group"
  color = local.networking_color
  href  = "/azure_insights.dashboard.network_security_group_detail?input.nsg_id={{.properties.'ID' | @uri}}"
  icon  = "enhanced_encryption"
}

category "network_subnet" {
  title = "Subnet"
  color = local.networking_color
  href  = "/azure_insights.dashboard.network_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  icon  = "lan"
}

category "network_virtual_network" {
  title = "Virtual Network"
  color = local.networking_color
  href  = "/azure_insights.dashboard.network_virtual_network_detail?input.vn_id={{.properties.'ID' | @uri}}"
  icon  = "cloud"
}

category "network_watcher_flow_log" {
  title = "Network Watcher Flow Log"
  color = local.networking_color
  icon  = "export_notes"
}
