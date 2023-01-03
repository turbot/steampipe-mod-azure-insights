locals {
  compute_common_tags = {
    service = "Azure/Compute"
  }
}

category "compute_disk" {
  title = "Compute Disk"
  href  = "/azure_insights.dashboard.compute_disk_detail?input.disk_id={{.properties.'ID' | @uri}}"
  icon  = "hard_drive"
  color = local.storage_color
}

category "compute_disk_access" {
  title = "Compute Disk Access"
  icon  = "check_circle"
  color = local.storage_color
}

category "compute_disk_encryption_set" {
  title = "Compute Disk Encryption Set"
  icon  = "key"
  color = local.security_color
}

category "compute_image" {
  title = "Compute Image"
  icon  = "developer_board"
  color = local.compute_color
}

category "compute_snapshot" {
  title = "Compute Snapshot"
  href  = "/azure_insights.dashboard.compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon  = "add_a_photo"
  color = local.storage_color
}

category "compute_virtual_machine" {
  title = "Compute Virtual Machine"
  href  = "/azure_insights.dashboard.compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = "memory"
  color = local.compute_color
}

category "compute_virtual_machine_scale_set" {
  title = "Compute Virtual Machine Scale Set"
  href  = "/azure_insights.dashboard.compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon  = "library_add"
  color = local.compute_color
}

category "compute_virtual_machine_scale_set_network_interface" {
  title = "Compute Virtual Machine Scale Set Network Interface"
  icon  = "settings_input_antenna"
  color = local.networking_color
}

category "compute_virtual_machine_scale_set_vm" {
  title = "Compute Virtual Machine Scale Set VM"
  href  = "/azure_insights.dashboard.compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon  = "memory"
  color = local.compute_color
}
