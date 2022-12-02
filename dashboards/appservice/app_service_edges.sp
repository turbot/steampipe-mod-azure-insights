edge "app_service_web_app_to_subnet" {
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

  param "web_app_ids" {}
}


edge "app_service_web_app_subnet_to_virtual_network" {
  title = "virtual network"

  sql = <<-EOQ
    select
      lower(id) as to_id,
      lower(sub ->> 'id') as from_id
    from
      azure_virtual_network,
      jsonb_array_elements(subnets) as sub
    where
      lower(sub ->> 'id') in (
        select
          lower(vnet_connection -> 'properties' ->> 'vnetResourceId')
        from
          azure_app_service_web_app
        where
          lower(id) = any($1)
      );
  EOQ

  param "web_app_ids" {}
}