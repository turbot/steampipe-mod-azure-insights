edge "app_service_web_app_to_app_service_plan" {
  title = "app service plan"

  sql = <<-EOQ
    select
      lower(id) as to_id,
      lower(app ->> 'ID') as from_id
    from
      azure_app_service_plan,
      jsonb_array_elements(apps) as app
    where
      lower(app ->> 'ID') = any($1);
  EOQ

  param "app_service_web_app_ids" {}
}

edge "app_service_web_app_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(s_id) as to_id,
      lower(w.id) as from_id
    from
      azure_app_service_web_app as w,
      lower(vnet_connection -> 'properties' ->> 'vnetResourceId') as s_id,
      azure_subnet as s
    where
      lower(s_id) = lower(s.id)
      and lower(w.id) = any($1);
  EOQ

  param "app_service_web_app_ids" {}
}
