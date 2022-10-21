locals {
  azure_storage_account_icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/storage_account.svg"))
  azure_key_vault_icon        = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/key_vault.svg"))
  azure_virtual_network_icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/virtual_network.svg"))
  azure_compute_disk_icon     = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_disk.svg"))
  azure_compute_snapshot_icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/compute_snapshot.svg"))
}