edge "activedirectory_group_to_activedirectory_directory_role" {
  title = "directory role"

  sql = <<-EOQ
    with assigned_role as(
      select
        id as id,
        title as title,
        tenant_id as tenant_id,
        jsonb_array_elements_text(member_ids) as m_id
      from
        azuread_directory_role
    )
    select
      g.id as from_id,
      ar.id as to_id
    from
      assigned_role as ar
      join azuread_group as g on g.id = ar.m_id
      join unnest($1::text[]) as u on g.id = split_part(u, '/', 1) and g.tenant_id = split_part(u, '/', 2);
  EOQ

  param "activedirectory_group_ids" {}
}

edge "activedirectory_group_to_activedirectory_group" {
  title = "has group"

  sql = <<-EOQ
    with group_details as(
      select
        id as id,
        tenant_id as tenant_id,
        jsonb_array_elements_text(member_ids) as m_id
      from
        azuread_group
    )
    select
      ag.id as from_id,
      g.id as to_id
    from
      group_details as ag
      join unnest($1::text[]) as u on ag.id = split_part(u, '/', 1) and ag.tenant_id = split_part(u, '/', 2)
      left join azuread_group as g on ag.m_id = g.id
    where
      ag.id = any($1);
  EOQ

  param "activedirectory_group_ids" {}
}

edge "activedirectory_group_to_activedirectory_user" {
  title = "has member"

  sql = <<-EOQ
    with group_details as(
      select
        id as id,
        title as title,
        tenant_id as tenant_id,
        jsonb_array_elements_text(member_ids) as m_id
      from
        azuread_group
    )
    select
      ag.id as from_id,
      au.id as to_id
    from
      group_details as ag
      join unnest($1::text[]) as u on ag.id = split_part(u, '/', 1) and ag.tenant_id = split_part(u, '/', 2)
      left join azuread_user as au on au.id = ag.m_id
    where
      ag.tenant_id = au.tenant_id;
  EOQ

  param "activedirectory_group_ids" {}
}

edge "activedirectory_group_to_subscription" {
  title = "subscription"

  sql = <<-EOQ
    select
      g.id as from_id,
      d.subscription_id as to_id
    from
      azuread_group as g
      join unnest($1::text[]) as u on g.id = split_part(u, '/', 1) and g.tenant_id = split_part(u, '/', 2)
      left join azure_role_assignment as a on a.principal_id = g.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      d.id is not null;
  EOQ

  param "activedirectory_group_ids" {}
}

edge "activedirectory_user_to_activedirectory_directory_role" {
  title = "directory role"

  sql = <<-EOQ
    with assigned_role as(
        select
        id as id,
        title as title,
        tenant_id as tenant_id,
        jsonb_array_elements_text(member_ids) as m_id
      from
        azuread_directory_role
    )
    select
      au.id as from_id,
      ar.id as to_id
    from
      assigned_role as ar
      left join azuread_user as au on au.id = ar.m_id
      join unnest($1::text[]) as u on au.id = split_part(u, '/', 1) and au.tenant_id = split_part(u, '/', 2);
  EOQ

  param "activedirectory_user_ids" {}
}

edge "activedirectory_user_to_subscription" {
  title = "subscription"

  sql = <<-EOQ
    select
      u.id as from_id,
      d.subscription_id as to_id
    from
      azuread_user as u
      join unnest($1::text[]) as i on u.id = split_part(i, '/', 1) and u.tenant_id = split_part(i, '/', 2)
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      d.id is not null;
  EOQ

  param "activedirectory_user_ids" {}
}

