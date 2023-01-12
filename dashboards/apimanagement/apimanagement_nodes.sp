node "api_management" {
  category = category.api_management

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
        'Provisioning State', provisioning_state,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_api_management
    where
      lower(id) = any($1);
  EOQ

  param "api_management_ids" {}
}