node "app_service_plan" {
  category = category.app_service_plan

  sql = <<-EOQ
    select
      lower(p.id) as id,
      p.title as title,
      json_build_object(
          'name', p.name,
          'id', lower(p.id),
          'type', p.type,
          'resource group', p.resource_group,
          'subscription id', p.subscription_id,
          'kind', p.kind,
          'sku name', p.sku_name,
          'sku size', p.sku_size,
          'sku tier', p.sku_tier,
          'sku capacity', p.sku_capacity
      ) as properties
    from
      azure_app_service_plan p
      cross join lateral jsonb_array_elements(p.apps) as a
      join unnest($1::text[]) as i on lower(a ->> 'id') = i and p.subscription_id = split_part(i, '/', 3);
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
      join unnest($1::text[]) as i on lower(id) = i and subscription_id = split_part(i, '/', 3);
  EOQ

  param "app_service_web_app_ids" {}
}
