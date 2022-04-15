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
      title = "Azure Active Directory Role Assignments"
      query = query.azuread_user_directory_role_sankey
      args  = {
        id = self.input.user_id.value
      }
    }

    flow {
      type  = "sankey"
      title = "Azure Role Assignments"
      query = query.azuread_user_subscription_role_sankey
      args  = {
        id = self.input.user_id.value
      }
    }

    table {
      title = "Azure Active Directory Role Assignments"
      width = 6
      query = query.azuread_directory_roles_for_user
      args  = {
        id = self.input.user_id.value
      }
    }

    table {
      title = "Azure Role Assignments"
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

query "azuread_user_subscription_role_sankey" {
  sql = <<-EOQ
    with args as (
      select $1 as azuread_user_id
    ),root_scope as (
      select
        distinct scope as scope,
        a.subscription_id as subscription_id,
        a.role_definition_id as role_definition_id,
        u.tenant_id as  tenant_id
      from
        azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
        where u.id = $1
        and a.scope = '/'
    ),
     resource_group_scope as (
      select
        distinct scope as scope,
        a.subscription_id as subscription_id,
        a.role_definition_id as role_definition_id
      from
        azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
        where u.id = $1
        and a.scope like '%/resourceGroups/%'
    ),
     subscription_scope as (
      select
        distinct scope as subscription_id,
        u.tenant_id as tenant_id
      from
        azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
        where u.id = $1
        and (a.scope like '/subscriptions/%' and a.scope not like '%/resourceGroups/%')
    ),management_group_children as (
        select
          id as id,
          name as name,
          c ->> 'id' as children_id,
          c ->> 'displayName' as children_name,
          parent ->> 'id' as parent_id,
          parent ->> 'name' as parent_name,
          tenant_id
        from
          azure_management_group,
          jsonb_array_elements (children) as c
      ),
      subscription_parent as (
        select
          distinct s.subscription_id as subscription_id,
          m.parent_id second_parent,
          m.name as name,
          m.id as subscription_parent,
          m.children_name as children_name,
          m.tenant_id as tenant_id
        from
          subscription_scope as s left join
          management_group_children as m on
          m.children_id = s.subscription_id
      ) ,
      management_parent_one as (
        select
          distinct s.second_parent as id,
          m.parent_id second_parent,
          m.id as parent_id,
          m.name as name,
          m.tenant_id as tenant_id
        from
          subscription_parent as s left join
          management_group_children as m on
          m.children_id = s.subscription_parent
      ),
      management_parent_two as (
        select
          distinct s.second_parent as id,
          m.parent_id second_parent,
          m.id as parent_id,
          m.name as parent_name,
          m.tenant_id as tenant_id
        from
          management_parent_one as s left join
          management_group_children as m on
          m.children_id = s.parent_id
    ),
    -- this is to handle case where we have any management level permissions
      only_management_scope as (
        select
          distinct scope as scope,
          u.title
        from
          azure_role_assignment as a left join azuread_user as u on a.principal_id = u.id
          where
           (a.scope like '/providers/Microsoft.Management/managementGroups%' or a.scope = '/')
            and u.id = $1 and a.scope not in (
              select subscription_parent as id from subscription_parent
              union select parent_id as id from management_parent_one
              union select parent_id as id from management_parent_two
            )
        ),
        only_management_scope_parent_one as (
          select
            m.parent_id second_parent,
            m.id as parent_id,
            m.children_id as children_id,
            m.children_name as children_name,
            m.name as name,
            m.tenant_id as tenant_id
          from
            only_management_scope as s left join
            management_group_children as m on
            m.children_id = s.scope
      ),
        only_management_scope_parent_two as (
        select
          distinct s.second_parent as id,
          m.parent_id second_parent,
          m.children_id as children_id,
          m.children_name as children_name,
          m.id as parent_id,
          m.name as name,
          m.tenant_id as tenant_id
        from
          only_management_scope_parent_one as s left join
          management_group_children as m on
          m.children_id = s.parent_id
      ),
       only_management_scope_parent_three as (
        select
          distinct s.second_parent as id,
          m.parent_id second_parent,
          m.children_id as children_id,
          m.children_name as children_name,
          m.id as parent_id,
          m.name as name,
          m.tenant_id as tenant_id
        from
          only_management_scope_parent_two as s left join
          management_group_children as m on
          m.children_id = s.parent_id
      ),
        only_management_scope_parent_four as (
        select
          distinct s.second_parent as id,
          m.parent_id as second_parent,
          m.children_id as children_id,
          m.children_name as children_name,
          m.id as parent_id,
          m.name as name,
          m.tenant_id as tenant_id
        from
          only_management_scope_parent_three as s left join
          management_group_children as m on
          m.children_id = s.parent_id
      )

   -- User
    select
      null as from_id,
      id as id,
      title,
      'azuread_user' as category
    from
      azuread_user
    where
      id in (select azuread_user_id from args)

      -- Azure root
     union select
      (select azuread_user_id from args) as from_id,
      s.scope as id,
      'Root' as title,
      'root' as category
    from
      root_scope as s left join azuread_user as u on s.tenant_id = u.tenant_id
      where
        u.id = $1

    -- Azure management parent level two (from subscription)
     union select
      (select azuread_user_id from args) as from_id,
      s.parent_id as id,
      s.parent_name as title,
      'subscriptions_parent' as category
    from
      management_parent_two as s left join azuread_user as u on s.tenant_id = u.tenant_id
      where
        u.id = $1

-- Azure direct managemnet groups level four
      union select
      r.scope as from_id,
      mg.children_id as id,
      mg.children_name as title,
      'management_group' as category
    from
      only_management_scope_parent_four as mg left join azuread_user as u on mg.tenant_id = u.tenant_id, root_scope as r
      where
        u.id = $1

  -- Azure management parent level one (from subscription)
     union select
      case when mg.parent_id is not null then mg.parent_id else (select azuread_user_id from args) end as from_id,
      s.parent_id as id,
      s.name as title,
      'subscriptions_parent' as category
    from
      management_parent_one as s left join azuread_user as u on s.tenant_id = u.tenant_id, management_parent_two as mg
      where
        u.id = $1

-- Azure direct managemnet groups level three
      union select
      case when mg.parent_id is not null then mg.parent_id else r.scope end  as from_id,
      s.parent_id as id,
      s.name as title,
      'management_group' as category
    from
      only_management_scope_parent_three as s left join azuread_user as u on s.tenant_id = u.tenant_id, only_management_scope_parent_four as mg, root_scope as r
      where
        u.id = $1

 -- Azure subscription parent (from subscription)
     union select
      mg.parent_id as from_id,
      s.subscription_parent as id,
      s.name as title,
      'subscriptions_parent' as category
    from
      subscription_parent as s left join azuread_user as u on s.tenant_id = u.tenant_id, management_parent_one as mg
      where
        u.id = $1

-- Azure direct managemnet groups level three
       union select
      case when mg.parent_id is not null then mg.parent_id else r.scope end as from_id,
      s.parent_id as id,
      s.name as title,
      'management_group' as category
    from
      only_management_scope_parent_two as s left join azuread_user as u on s.tenant_id = u.tenant_id, only_management_scope_parent_three as mg,
      root_scope as r
      where
        u.id = $1

-- Azure Subscription
     union select
      distinct mg.subscription_parent as from_id,
      s.id as id,
      s.display_name as title,
      'subscription' as category
    from
      azure_subscription as s left join azuread_user as u on s.tenant_id = u.tenant_id left join subscription_parent as mg
      on mg.subscription_id = s.id
      where
        s.id in (select subscription_id from subscription_scope)
        and u.id = $1

-- Azure direct managemnet groups level two
       union select
      mg.parent_id as from_id,
      s.parent_id  as id,
      s.name as title,
      'management_group' as category
    from
      only_management_scope_parent_one as s left join azuread_user as u on s.tenant_id = u.tenant_id, only_management_scope_parent_two as mg
      where
        u.id = $1

   -- Azure Resourcegroups
    union select
      concat ('/subscriptions/' || r.subscription_id) as from_id,
      r.scope as id,
      split_part(r.scope, '/', 4) || '/' || trim((split_part(r.scope, '/', 5)), '""') as title,
      'resource_group' as category
    from
      resource_group_scope as r left join azure_subscription as s on s.subscription_id =
      (split_part(r.scope, '/', 3) )

-- Azure direct managemnet groups level one
      union select
      s.parent_id as from_id,
      s.children_id  as id,
      s.children_name as title,
      'management_group' as category
    from
      only_management_scope_parent_one as s left join azuread_user as u on s.tenant_id = u.tenant_id
      where
        u.id = $1

   -- Azure Assigned Roles
      union select
      distinct a.scope as from_id,
      d.role_name as id,
      d.role_name as title,
      'role' as category
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id,
      azure_subscription as s
    where
      s.tenant_id = u.tenant_id and u.id = $1
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
      subscription_roles;
  EOQ

  param "id" {}
}

query "azuread_subscription_roles_for_user_without_mg" {
  sql = <<-EOQ
    with subscription_roles as (
      select
        distinct a.scope as scope,
        a.id as assignmnet_id,
         d.role_name as role_name

      from
        azure_role_assignment as a
        left join azure_role_definition as d on d.id = a.role_definition_id
      where
        a.scope like  '/subscriptions/%'
        and a.principal_id = $1
      order by
        d.role_name
    )
    select
      role_name as "Role Name",
      scope as "Scope",
      assignmnet_id as "Role Assignmnet ID"
    from
      subscription_roles;

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
