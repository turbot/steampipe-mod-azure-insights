locals {
  activedirectory_common_tags = {
    service = "Azure/ActiveDirectory"
  }
}

category "activedirectory_directory_role" {
  title = "Azuread Directory Role"
  color = local.iam_color
  icon  = "engineering"
}

category "activedirectory_group" {
  title = "Azuread Group"
  color = local.iam_color
  href  = "/azure_insights.dashboard.activedirectory_group_detail?input.group_id={{.properties.'ID' | @uri}}"
  icon  = "group"
}

category "activedirectory_role_assignment" {
  title = "Azuread Assigned Role"
  color = local.iam_color
  icon  = "assignment"
}

category "activedirectory_user" {
  title = "Azuread User"
  color = local.iam_color
  href  = "/azure_insights.dashboard.activedirectory_user_detail?input.user_id={{.properties.'ID' | @uri}}"
  icon  = "person"
}

category "azure_role_definition" {
  title = "Azure Role Definition"
  color = local.iam_color
  icon  = "engineering"
}