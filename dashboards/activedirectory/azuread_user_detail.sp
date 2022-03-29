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
      title = "Attached Subscription Roles"
      query = query.azuread_user_subscription_role_sankey
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
    select
      u.title as label,
      u.id as value,
      json_build_object(
        'subscription', s.display_name
      ) as tags
    from
      azuread_user as u,
      azure_subscription as s
    where
      u.tenant_id = s.tenant_id
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
      g.id as id,
      g.display_name as title,
      1 as depth,
      'azuread_group' as category
    from
      azuread_group as g,
      jsonb_array_elements(member_ids) as m
    where
      trim((m::text), '""') = (select azuread_user_id from args)

    -- Directory Roles
    union select
      (select azuread_user_id from args) as from_id,
      dr.id as id,
      dr.display_name || ' (Directory Roles)' as title,
      2 as depth,
      'azuread_directory_roles' as category
    from
      azuread_directory_role as dr,
      jsonb_array_elements(member_ids) as m
    where
      trim((m::text), '""') = (select azuread_user_id from args)

  -- Directory Roles inherited from  groups
    union select
      trim((m::text), '""') as from_id,
      dr.id as id,
      dr.display_name || ' (Directory Roles)' as title,
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

    -- Azure Subscription
     union select
      (select azuread_user_id from args) as from_id,
      s.title as title,
      s.title as id,
      1 as depth,
      'azure_subscription' as category
    from
      azure_subscription as s left join azuread_user as u  on s.tenant_id = u.tenant_id
      where u.id = (select azuread_user_id from args)

   -- Azure Assigned Roles
    union select
      s.title as from_id,
      d.role_name as title,
      d.role_name as id,
      2 as depth,
      'azure_role_assignment' as category
    from
     azuread_user as u
    left join azure_role_assignment as a on a.principal_id = u.id
    left join azure_role_definition as d on d.id = a.role_definition_id,
    azure_subscription as s
    where s.tenant_id = u.tenant_id and u.id = $1

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
    id as "ID"
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
            trim((m::text), '""') = $1
    ) data
  order by
    role_name;

  EOQ

  param "id" {}
}

query "azuread_subscription_roles_for_user" {
  sql = <<-EOQ
    select
      d.role_name as "Role Name",
      a.scope as "Scope",
      d.id as "ID"
    from
      azure_role_assignment as a
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      a.principal_id = $1
    order by
      d.role_name;
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
