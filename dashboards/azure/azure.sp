locals {
  azure_common_tags = {
    service = "Azure"
  }
}

category "resource_group" {
  title = "Resource Group"
  color = local.compute_color
  icon  = "travel_explore"
}

category "subscription" {
  title = "Subscription"
  color = local.compute_color
  icon  = "cloud_circle"
}