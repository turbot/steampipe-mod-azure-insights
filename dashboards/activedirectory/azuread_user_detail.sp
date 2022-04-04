dashboard "azuread_user_detail" {

  title          = "Azure Active Directory User Detail"
   documentation = file("./dashboards/activedirectory/docs/azuread_user_detail.md")

  tags = merge(local.activedirectory_common_tags, {
    type = "Detail"
  })

  input "user_id" {
    title = "Select a user:"
    query = query.azuread_user_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azuread_user_type
      args = {
        id = self.input.user_id.value
      }
    }

  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.azuread_user_overview
      args = {
        id = self.input.user_id.value
      }

    }

    container {

      width = 6

      table {
        title = "Last 5 Sign-ins"
        query = query.azuread_user_sign_in_report
        args  = {
          id = self.input.user_id.value
        }
      }

    }

  }

  container {

    title = "Azure Active Directory User Role Analysis"

    flow {
      type  = "sankey"
      title = "Attached Directory Roles"
      query = query.azuread_user_directory_role_sankey
      args  = {
        id = self.input.user_id.value
      }
    }

    flow {
      type  = "sankey"
      title = "Attached Subscription Roles (With managemnet group)"
      query = query.azuread_user_subscription_role_sankey_one
      args  = {
        id = self.input.user_id.value
      }
    }

    flow {
      type  = "sankey"
      title = "Attached Subscription Roles (Recommended)"
      query = query.azuread_user_subscription_role_sankey_two
      args  = {
        id = self.input.user_id.value
      }
    }

    table {
      title = "Directory Roles"
      width = 6
      query = query.azuread_directory_roles_for_user
      args  = {
        id = self.input.user_id.value
      }
    }

    table {
      title = "Subscription Roles"
      width = 6
      query = query.azuread_subscription_roles_for_user
      args  = {
        id = self.input.user_id.value
      }
    }

  }

  table {
    title = "Groups"
    width = 12

    column "Display Name" {
      href = "${dashboard.azuread_group_detail.url_path}?input.group_id={{.ID | @uri}}"
    }

    query = query.azuread_groups_for_user
    args  = {
      id = self.input.user_id.value
    }

  }

}

query "azuread_user_input" {
  sql = <<-EOQ
    with tenants as (
      select
        distinct tenant_id,
        name
      from
        azure_tenant
    )
    select
      u.title as label,
      u.id as value,
      json_build_object(
        'tenant', u.tenant_id
      ) as tags
    from
      azuread_user as u ,
      tenants as t
    where
      u.tenant_id = t.tenant_id
    order by
      u.title;
  EOQ
}

query "azuread_user_type" {
  sql = <<-EOQ
    select
      'User Type' as label,
      user_type as value
    from
      azuread_user
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azuread_user_overview" {
  sql = <<-EOQ
    select
      display_name as "Display Name",
      given_name as "Given Name",
      user_principal_name as "User Principal Name",
      created_date_time as "Created Date Time",
      title as "Title",
      tenant_id as "Tenant ID",
      id as "ID"
    from
      azuread_user
    where
      id = $1
  EOQ

  param "id" {}
}

query "azuread_user_directory_role_sankey" {
  sql = <<-EOQ

    with args as (
      select $1 as azuread_user_id
    ), groups as (
        select
          g.id as id
        from
          azuread_group as g,
          jsonb_array_elements(member_ids) as m
        where
          trim((m::text), '""') = (select azuread_user_id from args)
        ) ,
        groups_with_role as (
          select
            trim((m::text), '""') as group_id
          from
            azuread_directory_role,
            jsonb_array_elements(member_ids) as m
          where
            trim((m::text), '""') in (select id from groups)
      )

    -- User
    select
      null as from_id,
      id as id,
      title,
      0 as depth,
      'azuread_user' as category
    from
      azuread_user
    where
      id in (select azuread_user_id from args)

  -- Groups
    union select
      (select azuread_user_id from args) as from_id,
      group_id as id,
      g.display_name as title,
      1 as depth,
      'azuread_group' as category
    from
      groups_with_role as gr left join azuread_group as g on g.id = gr.group_id

    -- Directory Roles
    union select
      (select azuread_user_id from args) as from_id,
      dr.id as id,
      dr.display_name as title,
      2 as depth,
      'azuread_directory_roles' as category
    from
      azuread_directory_role as dr,
      jsonb_array_elements(member_ids) as m
    where
      trim((m::text), '""') = (select azuread_user_id from args)

    -- Directory Roles inherited from groups
    union select
      trim((m::text), '""') as from_id,
      dr.id as id,
      dr.display_name  as title,
      2 as depth,
      'azuread_directory_roles' as category
    from
      azuread_directory_role as dr,
      jsonb_array_elements(member_ids) as m
    where
      trim((m::text), '""') in (select
        g.id as id
      from
        azuread_group as g,
        jsonb_array_elements(member_ids) as m
      where
        trim((m::text), '""') = (select azuread_user_id from args))
  EOQ

  param "id" {}
}

query "azuread_user_subscription_role_sankey_one" {
  sql = <<-EOQ
    with args as (
      select $1 as azuread_user_id
    ), user_scope as (
        select
          distinct a.scope as id,
          a.id as role_assign
        from
          azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
          where u.id = $1
    ), managment_role_assign_id as (
      select
          distinct user_scope.role_assign as role_assign_id,
          mg.display_name as managment_group_name,
          mg.id as managment_group_id

        from
          azuread_user as u,
          azure_subscription as sub,
          azure_management_group as mg,
          user_scope
        where
          sub.tenant_id = u.tenant_id and u.id = $1
          and (user_scope.id = mg.id )
      ),
      resource_group_scope as (
          select
            distinct scope as id
          from
            azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
            where u.id = $1
            and a.scope like '%/resourceGroups/%'
      ),
      root_management as (
        select
          distinct id,
          name,
          display_name as displayName,
          children
        from
          azure_management_group as mg
        where
          parent is null
        ),
        second_level_managemnet as(
          select
            distinct (c ->> 'id')  as id,
            r.id as parent_id,
            r.displayName as parent_name,
            c ->> 'displayName' as displayName,
            c ->> 'type' as type
          from
            azure_management_group as mg,
            jsonb_array_elements(children) as c,
            root_management as r
          where
            mg.id = r.id
        ),
      third_level_managemnet as (
        select
          distinct  (c ->> 'id' ) as id,
            r.id as parent_id,
            r.displayName as parent_name,
          c ->> 'displayName' as displayName,
          c ->> 'type' as type
        from
          azure_management_group as mg,
          jsonb_array_elements(children) as c,
          second_level_managemnet as r
      where
        mg.id = r.id
      ), fourth_level_managemnet as (
          select
            distinct  (c ->> 'id' ) as id,
            r.id as parent_id,
            r.displayName as parent_name,
            c ->> 'displayName' as displayName,
            c ->> 'type' as type
          from
            azure_management_group mg,
          jsonb_array_elements(children) as c,
            third_level_managemnet as r
        where
          mg.id = r.id
      ),
       fifth_level_managemnet as (
          select
            distinct  (c ->> 'id' ) as id,
                        r.id as parent_id,
              r.displayName as parent_name,
            c ->> 'displayName' as displayName,
            c ->> 'type' as type
          from
            azure_management_group mg,
          jsonb_array_elements(children) as c,
            fourth_level_managemnet as r
        where
          mg.id = r.id
      ), sixth_level_managemnet as(
          select
            distinct (c ->> 'id' ) as id,
            r.id as parent_id,
            r.displayName as parent_name,
            c ->> 'displayName' as displayName,
            c ->> 'type' as type
          from
              azure_management_group mg,
          jsonb_array_elements(children) as c,
            fifth_level_managemnet as r
        where
          mg.id = r.id
      )

    -- User
    select
      null as from_id,
      id as id,
      title,
      0 as depth,
      'azuread_user' as category
    from
      azuread_user
    where
      id in (select azuread_user_id from args)

    -- Azure root Managament groups
    union select
      (select azuread_user_id from args) as from_id,
      displayName as title,
      displayName as id,
      1 as depth,
      'azure_management_group' as category
    from
      root_management

    -- Azure  Managament groups 2nd level
    union select
      parent_name as from_id,
      displayName as title,
      displayName as id,
      2 as depth,
      'azure_management_group' as category
    from
      second_level_managemnet

       -- Azure  Managament groups 3rd level
    union select
      parent_name as from_id,
      displayName as title,
      displayName as id,
      3 as depth,
      'azure_management_group' as category
    from
      third_level_managemnet

      -- Azure  Managament groups 4 level
    union select
      parent_name as from_id,
      displayName as title,
      displayName as id,
      4 as depth,
      'azure_management_group' as category
    from
      fourth_level_managemnet

    -- Azure  Managament groups 5 level
    union select
      parent_name as from_id,
      displayName as title,
      displayName as id,
      5 as depth,
      'azure_management_group' as category
    from
      fifth_level_managemnet


  -- Azure  Managament groups 6 level
    union select
      parent_name as from_id,
      displayName as title,
      displayName as id,
      5 as depth,
      'azure_management_group' as category
    from
      sixth_level_managemnet

        -- Azure Assigned Roles on management
    union select
      distinct m.managment_group_name as from_id,
      d.role_name as id,
      d.role_name as title,
      6 as depth,
    'role' as category
      from
      managment_role_assign_id as m
      left join azure_role_assignment as a on m.role_assign_id = a.id
      left join azure_role_definition as d on d.id = a.role_definition_id

  EOQ

  param "id" {}
}

query "azuread_user_subscription_role_sankey_two" {
  sql = <<-EOQ
   with args as (
      select $1 as azuread_user_id
    ), management_scope as (
        select
          distinct scope as scope
        from
          azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
          where u.id = (select azuread_user_id from args)
          and a.scope like '/providers/Microsoft.Management/managementGroups%'
    ),
     resource_group_scope as (
      select
        distinct scope as scope
      from
        azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
        where u.id = (select azuread_user_id from args)
        and a.scope like '%/resourceGroups/%'
    )

    -- User
    select
      null as from_id,
      id as id,
      title,
      0 as depth,
      'azuread_user' as category
    from
      azuread_user
    where
      id in (select azuread_user_id from args)

    -- Azure Managament groups
    union select
      (select azuread_user_id from args) as from_id,
      split_part(s.scope, '/', 4) || '/' || trim((split_part(s.scope, '/', 5)), '""') as title,
      split_part(s.scope, '/', 4) || '/' || trim((split_part(s.scope, '/', 5)), '""') as id,
      1 as depth,
      'azure_management_group' as category
    from
      management_scope as s

    -- Root
    union select
      (select azuread_user_id from args) as from_id,
      a.scope || ' (Root)'as title,
      a.scope || ' (Root)' as id,
      1 as depth,
      'root' as category
    from
      azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
      where u.id = (select azuread_user_id from args)
      and a.scope = '/'

    -- Azure Subscription
     union select
      (select azuread_user_id from args) as from_id,
      s.title as title,
      s.title as id,
      1 as depth,
      'azure_subscription' as category
    from
      azure_subscription as s left join azuread_user as u  on s.tenant_id = u.tenant_id
      where
        u.id = (select azuread_user_id from args)

    -- Azure Resourcegroups
    union select
      (s.title)::text as from_id,
      split_part(r.scope, '/', 4) || '/' || trim((split_part(r.scope, '/', 5)), '""') as title,
      split_part(r.scope, '/', 4) || '/' || trim((split_part(r.scope, '/', 5)), '""') as id,
      2 as depth,
      'resource_group_scope' as category
    from
      resource_group_scope as r left join azure_subscription as s on s.subscription_id =
      (split_part(r.scope, '/', 3) )

   -- Azure Assigned Roles on subscription
    union select
      s.title as from_id,
      d.role_name as title,
      d.role_name as id,
      3 as depth,
      'azure_subscription' as category
    from
     azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id,
      azure_subscription as s
    where s.subscription_id = a.subscription_id and u.id = $1
      and (a.scope like '/subscriptions/%' and a.scope not like '%/resourceGroups/%')

    -- Azure Assigned Roles on management
    union select
      split_part(sc.scope, '/', 4) || '/' || trim((split_part(sc.scope, '/', 5)), '""')  as from_id,
      d.role_name as title,
      d.role_name as id,
      3 as depth,
      'azure_management_group' as category
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id,
      azure_subscription as s,
      resource_group_scope as sc
    where
      s.tenant_id = u.tenant_id and u.id = $1
      and a.scope like '%/resourceGroups/%'

     -- Azure Assigned Roles on resourceGroups
    union select
      split_part(sc.scope, '/', 4) || '/' || trim((split_part(sc.scope, '/', 5)), '""') as from_id,
      d.role_name as title,
      d.role_name as id,
      3 as depth,
      'azure_role_assignment' as category
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id,
      azure_subscription as s,
      management_scope  as sc
    where
      s.tenant_id = u.tenant_id and u.id = $1
      and a.scope like '/providers/Microsoft.Management/managementGroups%'

    -- Azure Assigned Roles on root
    union select
      a.scope || ' (Root)' as from_id,
      d.role_name as title,
      d.role_name as id,
      3 as depth,
      'root' as category
    from
      azuread_user as u left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
      where u.id = (select azuread_user_id from args)
      and a.scope = '/'

  EOQ

  param "id" {}
}

query "azuread_groups_for_user" {
  sql = <<-EOQ
    select
      g.display_name as "Display Name",
      g.id as "ID",
      g.is_subscribed_by_mail as "Is Subscribed By Mail",
      g.expiration_date_time as "Expiration Date Time"
    from
      azuread_group as g,
      jsonb_array_elements(member_ids) as m
    where
      trim((m::text), '""') = $1
    order by
      g.display_name ;
  EOQ

  param "id" {}
}

query "azuread_directory_roles_for_user" {
  sql = <<-EOQ

  select
    role_name as "Role Name",
    id as "Role ID"
  from
    (
      select
        dr.display_name as role_name,
        dr.id as id
      from
        azuread_directory_role as dr,
        jsonb_array_elements(member_ids) as m
      where
        trim((m::text), '""') = $1

      union select
        dr.display_name as role_name,
        dr.id as id
      from
        azuread_directory_role as dr,
        jsonb_array_elements(member_ids) as m
      where
        trim((m::text), '""') in (select
            g.id as id
          from
            azuread_group as g,
            jsonb_array_elements(member_ids) as m
          where
            trim((m::text), '""') = $1)
    ) data
  order by
    role_name;

  EOQ

  param "id" {}
}

query "azuread_subscription_roles_for_user" {
  sql = <<-EOQ
    with subscription_roles as (
      select
        distinct  a.scope as scope,
         a.id as assignmnet_id,
        d.role_name as role_name

      from
        azure_role_assignment as a
        left join azure_role_definition as d on d.id = a.role_definition_id
      where
        a.principal_id = $1
      order by
        d.role_name
    )
    select
      role_name as "Role Name",
      scope as "Scope",
      assignmnet_id as "Role Assignmnet ID"
    from
      subscription_roles

  EOQ

  param "id" {}
}

query "azuread_user_sign_in_report" {
  sql = <<-EOQ
    select
      id as "ID",
      created_date_time as "Created Date Time",
      app_display_name as "App Display Name",
      client_app_used as "Client App Used"
    from
      azuread_sign_in_report
    where
      user_id = $1
    order by
      created_date_time desc
    limit 5;
  EOQ

  param "id" {}
}
