locals {
  compute_common_tags = {
    service = "Azure/Compute"
  }
}

category "compute_disk" {
  title = "Compute Disk"
  color = local.storage_color
  href  = "/azure_insights.dashboard.compute_disk_detail?input.disk_id={{.properties.'ID' | @uri}}"
  icon  = "hard_drive"
}

category "compute_disk_access" {
  title = "Compute Disk Access"
  color = local.storage_color
  icon  = "check_circle"
}

category "compute_disk_encryption_set" {
  title = "Compute Disk Encryption Set"
  color = local.security_color
  icon  = "key"
}

category "compute_image" {
  title = "Compute Image"
  color = local.compute_color
  icon  = "developer_board"
}

category "compute_snapshot" {
  title = "Compute Snapshot"
  color = local.storage_color
  href  = "/azure_insights.dashboard.compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon  = "add_a_photo"
}

category "compute_virtual_machine" {
  title = "Compute Virtual Machine"
  color = local.compute_color
  href  = "/azure_insights.dashboard.compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = "memory"
}

category "compute_virtual_machine_scale_set" {
  title = "Compute Virtual Machine Scale Set"
  color = local.compute_color
  href  = "/azure_insights.dashboard.compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon  = "library_add"
}

category "compute_virtual_machine_scale_set_network_interface" {
  title = "Compute Virtual Machine Scale Set Network Interface"
  color = local.networking_color
  icon  = "settings_input_antenna"
}

category "compute_virtual_machine_scale_set_vm" {
  title = "Compute Virtual Machine Scale Set VM"
  color = local.compute_color
  href  = "/azure_insights.dashboard.compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon  = "memory"
}
