node "resource_group" {
  category = category.resource_group

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Subscription ID', subscription_id,
        'Provisioning State', provisioning_state,
        'Managed By', managed_by
      ) as properties
    from
      azure_resource_group
    where
      id = any($1);
  EOQ

  param "resource_group_ids" {}
}

node "subscription" {
  category = category.subscription

  sql = <<-EOQ
    select
      subscription_id as id,
      title as title,
      jsonb_build_object(
        'Display Name', display_name,
        'ID', id,
        'Authorization Source', authorization_source,
        'State', state,
        'Tenant ID', tenant_id
      ) as properties
    from
      azure_subscription
    where
      subscription_id = any($1);
  EOQ

  param "subscription_ids" {}
}