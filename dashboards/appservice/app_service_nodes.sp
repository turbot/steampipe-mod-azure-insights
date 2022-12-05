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
