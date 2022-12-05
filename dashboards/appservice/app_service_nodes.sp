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

  param "web_app_ids" {}
}

node "app_service_web_app_app_service_plan" {
  category = category.app_service_plan

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      json_build_object(
        'Name', name,
        'ID', id,
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

  param "web_app_ids" {}
}

node "app_service_web_app_network_application_gateway" {
  category = category.network_application_gateway

  sql = <<-EOQ
    with application_gateway as (
      select
        g.id as id,
        g.name as name,
        g.subscription_id,
        g.resource_group,
        g.title,
        g.region,
        backend_address ->> 'fqdn' as app_host_name
      from
        azure_application_gateway as g,
        jsonb_array_elements(backend_address_pools) as pool,
        jsonb_array_elements(pool -> 'properties' -> 'backendAddresses') as backend_address
    )
    select
      lower(g.id) as id,
      g.title as title,
      jsonb_build_object(
        'Name', g.name,
        'ID', g.id,
        'Subscription ID', g.subscription_id,
        'Resource Group', g.resource_group,
        'Region', g.region
      ) as properties
    from
      azure_app_service_web_app as a,
      jsonb_array_elements(a.host_names) as host_name,
      application_gateway as g
    where
      lower(g.app_host_name) = lower(trim((host_name::text), '""'))
      and lower(a.id) = any($1);
  EOQ

  param "web_app_ids" {}
}