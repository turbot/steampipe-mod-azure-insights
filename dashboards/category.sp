category "azuread_user" {
  icon = local.azuread_user_icon
  fold {
    title     = "Azuread User"
    threshold = 3
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

category "azuread_role_assignment"{
  icon = local.azuread_assigned_role_icon
  fold{
    title     = "Azuread Assigned Role"
    threshold = 3
  }
}