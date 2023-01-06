locals {
  azure_common_tags = {
    service = "Azure"
  }
}

category "subscription" {
  title = "Subscription"
  color = local.compute_color
  icon  = "cloud_circle"
}
