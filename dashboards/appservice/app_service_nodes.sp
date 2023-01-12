node "app_service_plan" {
  category = category.app_service_plan

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      json_build_object(
        'Name', name,
        'ID', lower(id),
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'Kind', kind,
        'SKU Name', sku_name,
        'SKU Size', sku_size,
        'SKU Tier', sku_tier,
        'SKU Capacity', sku_capacity
      ) as properties
    from
      azure_app_service_plan,
      jsonb_array_elements(apps) as app
    where
      lower(app ->> 'ID') = any($1);
  EOQ

  param "app_service_web_app_ids" {}
}

node "app_service_web_app" {
  category = category.app_service_web_app

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Name', name,
        'Type', type,
        'Kind', kind,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_app_service_web_app
    where
      lower(id) = any($1)
  EOQ

  param "app_service_web_app_ids" {}
}
