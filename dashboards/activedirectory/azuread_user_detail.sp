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

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azuread_user_node,
        node.azuread_user_from_group_node,
        node.azuread_user_from_directory_role_node
      ]

      edges = [
        edge.azuread_user_from_group_edge,
        edge.azuread_user_from_directory_role_edge
      ]

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
      created_date_time as "Create Time",
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

query "azuread_groups_for_user" {
  sql = <<-EOQ
    select
      g.display_name as "Display Name",
      g.id as "ID",
      g.is_subscribed_by_mail as "Is Subscribed By Mail",
      g.expiration_date_time as "Expiration Time"
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

query "azuread_user_sign_in_report" {
  sql = <<-EOQ
    select
      id as "ID",
      created_date_time as "Create Time",
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

node "azuread_user_node" {
category = category.azuread_user

sql = <<-EOQ
     select
      id as id,
      title as title,
       jsonb_build_object(
      'Tenant ID', tenant_id
      ) as properties
    from
      azuread_user
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azuread_user_from_group_node" {
category=category.azuread_group

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
      ag.id as id,
      ag.title as title,
       jsonb_build_object(
      'Tenant ID', ag.tenant_id
      ) as properties
    from
      group_details as ag
      left join azuread_user as au on au.id=ag.m_id
    where
     au.id = $1
  EOQ

  param "id" {}
}

edge "azuread_user_from_group_edge" {
  title = "Azuread Group"

  sql = <<-EOQ
   with group_details as(
        select
        id as id,
        title as title,
        jsonb_array_elements_text(member_ids) as m_id
      from
        azuread_group
    )
     select
      au.id as from_id,
      ag.id as to_id,
      ag.title as title
    from
      group_details as ag
      left join azuread_user as au on au.id=ag.m_id
    where
     au.id = $1
  EOQ

  param "id" {}
}

node "azuread_user_from_directory_role_node" {
category=category.azuread_directory_role

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
      ar.id as id,
      ar.title as title,
       jsonb_build_object(
      'Tenant ID', ar.tenant_id
      ) as properties
    from
      assigned_role as ar
      left join azuread_user as au on au.id = ar.m_id
    where
     au.id = $1
  EOQ

  param "id" {}
}

edge "azuread_user_from_directory_role_edge" {
title = "Azuread Directory Role"

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
      ar.id as to_id,
      ar.title as title
    from
      assigned_role as ar
      left join azuread_user as au on au.id = ar.m_id
    where
     au.id = $1
  EOQ

   param "id" {}
}