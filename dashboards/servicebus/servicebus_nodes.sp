node "servicebus_namespace" {
  category = category.servicebus_namespace

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
      azure_servicebus_namespace
    where
      lower(id) = any($1);
  EOQ

  param "servicebus_namespace_ids" {}
}
