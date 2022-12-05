locals {
  compute_common_tags = {
    service = "Azure/Compute"
  }
}

category "azure_compute_disk" {
  title = "Compute Disk"
  href  = "/azure_insights.dashboard.compute_disk_detail?input.d_id={{.properties.'ID' | @uri}}"
  icon  = "inbox-stack"
  color = local.storage_color
}

category "azure_compute_disk_access" {
  title = "Compute Disk Access"
  icon  = "text:DiskAccess"
  color = local.storage_color
}

category "azure_compute_disk_encryption_set" {
  title = "Compute Disk Encryption Set"
  icon  = "text:DES"
  color = local.security_color
}

category "azure_compute_image" {
  title = "Compute Image"
  icon  = "text:Image"
  color = local.compute_color
}

category "azure_compute_snapshot" {
  title = "Compute Snapshot"
  href  = "/azure_insights.dashboard.compute_snapshot_detail?input.id={{.properties.'ID' | @uri}}"
  icon  = "viewfinder-circle"
  color = local.storage_color
}

category "azure_compute_virtual_machine" {
  title = "Compute Virtual Machine"
  href  = "/azure_insights.dashboard.compute_virtual_machine_detail?input.vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = local.compute_color
}

category "azure_compute_virtual_machine_scale_set" {
  title = "Compute Virtual Machine Scale Set"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_detail?input.vm_scale_set_id={{.properties.'ID' | @uri}}"
  icon  = "square-2-stack"
  color = local.compute_color
}

category "azure_compute_virtual_machine_scale_set_network_interface" {
  title = "Compute Virtual Machine Scale Set Network Interface"
  icon  = "text:eni"
  color = local.network_color
}

category "azure_compute_virtual_machine_scale_set_vm" {
  title = "Compute Virtual Machine Scale Set VM"
  href  = "/azure_insights.dashboard.azure_compute_virtual_machine_scale_set_vm_detail?input.scale_set_vm_id={{.properties.'ID' | @uri}}"
  icon  = "cpu-chip"
  color = local.compute_color
}