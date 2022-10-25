locals {
  azure_compute_virtual_machine_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_virtual_machine.svg"))
  azure_public_ip_icon               = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/public_ip.svg"))
  azure_network_interface_icon       = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/network_interface.svg"))
  azure_manage_disk_icon             = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/manage_disk.svg"))
  azure_image_icon                   = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/image.svg"))
  azure_network_security_group_icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/network_security_group.svg"))
  azure_security_profile_icon        = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/security_profile.svg"))
  azuread_user_icon                  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/user.svg"))
  azuread_group_icon                 = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/group.svg"))
  azuread_assigned_role_icon         = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/assigned_roles.svg"))
  azuread_directory_role_icon        = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/directory_roles.svg"))
}