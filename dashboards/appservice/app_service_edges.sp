edge "app_service_web_app_to_app_service_plan" {
  title = "app service plan"

  sql = <<-EOQ
    select
      lower(p.id) as to_id,
      lower(a ->> 'ID') as from_id
    from
      azure_app_service_plan p
      cross join lateral jsonb_array_elements(p.apps) as a
      join unnest($1::text[]) as i on lower(a ->> 'ID') = lower(i) and p.subscription_id = split_part(i, '/', 3);
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
      azure_app_service_web_app as w
      join unnest($1::text[]) as i on lower(w.id) = i and w.subscription_id = split_part(i, '/', 3),
      lower(vnet_connection -> 'properties' ->> 'vnetResourceId') as s_id,
      azure_subnet as s
    where
      lower(s_id) = lower(s.id)
      and lower(w.id) = any($1);
  EOQ

  param "app_service_web_app_ids" {}
}
