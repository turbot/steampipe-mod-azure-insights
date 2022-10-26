locals {
  azure_compute_disk_icon            = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_disk.svg"))
  azure_compute_snapshot_icon        = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_snapshot.svg"))
  azure_compute_virtual_machine_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_virtual_machine.svg"))
  azure_image_icon                   = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/image.svg"))
  azure_key_vault_icon               = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/key_vault.svg"))
  azure_manage_disk_icon             = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/manage_disk.svg"))
  azure_network_interface_icon       = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/network_interface.svg"))
  azure_network_security_group_icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/network_security_group.svg"))
  azure_public_ip_icon               = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/public_ip.svg"))
  azure_security_profile_icon        = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/security_profile.svg"))
  azure_storage_account_icon         = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/storage_account.svg"))
  azure_virtual_network_icon         = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/virtual_network.svg"))
}