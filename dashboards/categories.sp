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

category "azure_security_profile" {
  icon = local.azure_security_profile_icon
  fold {
    title     = "Security Profile"
    threshold = 3
  }
}

category "azure_network_security_group" {
  icon = local.azure_network_security_group_icon
  fold {
    title     = "NSG"
    threshold = 3
  }
}

category "azuread_user" {
  icon = local.azuread_user_icon
  fold {
    title     = "Azuread User"
    threshold = 5
  }
}

category "azuread_group" {
  icon = local.azuread_group_icon
  fold {
    title     = "Azuread Group"
    threshold = 3
  }
}

category "azuread_directory_role" {
  icon = local.azuread_directory_role_icon
  fold {
    title     = "Azuread Directory Role"
    threshold = 3
  }
}

category "azuread_role_assignment" {
  icon = local.azuread_assigned_role_icon
  fold {
    title     = "Azuread Assigned Role"
    threshold = 3
  }
}