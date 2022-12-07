node "container_registry" {
  category = category.container_registry

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Provisioning State', provisioning_state,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_container_registry
    where
      lower(id) = any($1);
  EOQ

  param "container_registry_ids" {}
}