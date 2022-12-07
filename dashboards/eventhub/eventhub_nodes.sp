node "eventhub_namespace" {
  category = category.eventhub_namespace

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
        'Provisioning State', provisioning_state,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_eventhub_namespace
    where
      id = any($1);
  EOQ

  param "eventhub_namespace_ids" {}
}