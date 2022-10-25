category "azure_compute_virtual_machine" {
  icon = local.azure_compute_virtual_machine_icon
  fold {
    title     = "Compute Virtual Machine"
    threshold = 3
  }
}

category "azure_managed_disk" {
  icon = local.azure_manage_disk_icon
  fold {
    title     = "Managed Disk"
    threshold = 3
  }
}

category "azure_network_interface" {
  icon = local.azure_network_interface_icon
  fold {
    title     = "Network Interface"
    threshold = 3
  }
}

category "azure_public_ip" {
  icon = local.azure_public_ip_icon
  fold {
    title     = "Public IP"
    threshold = 3
  }
}

category "azure_image" {
  icon = local.azure_image_icon
  fold {
    title     = "Image"
    threshold = 3
  }
}