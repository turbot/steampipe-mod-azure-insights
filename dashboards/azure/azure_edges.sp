edge "resource_group_to_role_definition" {
  title = "assigned role"

  sql = <<-EOQ
    select
      d.id as to_id,
      a.scope as from_id
    from
      azure_role_definition as d
      left join azure_role_assignment as a on a.role_definition_id = d.id
      left join azure_resource_group as r on r.id = a.scope
    where
      (a.scope like '%/resourceGroups/%')
      or (a.scope like '%/resourcegroups/%')
      and d.id = any($1);
  EOQ

  param "role_definition_ids" {}
}

edge "subscription_to_resource_group" {
  title = "resource group"

  sql = <<-EOQ
    select
      g.subscription_id as from_id,
      g.id as to_id
    from
      azure_resource_group as g
    where
      g.subscription_id = any($1)
   EOQ

  param "subscription_ids" {}
}

edge "subscription_to_role_definition" {
  title = "assigned role"

  sql = <<-EOQ
    select
      distinct d.id as to_id,
      d.subscription_id as from_id
    from
      azure_role_definition as d
      left join azure_role_assignment as a on a.role_definition_id = d.id
    where
      (a.scope like '/subscriptions/%' and a.scope not like '%/resourceGroups/%')
      and (a.scope like '/subscriptions/%' and a.scope not like '%/resourcegroups/%')
      and d.id = any($1)
  EOQ

  param "role_definition_ids" {}
}
