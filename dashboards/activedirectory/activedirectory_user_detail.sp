dashboard "activedirectory_user_detail" {

  title         = "Azure Active Directory User Detail"
  documentation = file("./dashboards/activedirectory/docs/activedirectory_user_detail.md")

  tags = merge(local.activedirectory_common_tags, {
    type = "Detail"
  })

  input "user_id" {
    title = "Select a user:"
    query = query.activedirectory_user_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.activedirectory_user_type
      args = {
        id = self.input.user_id.value
      }
    }

  }

  with "activedirectory_directory_roles_for_activedirectory_user" {
    query = query.activedirectory_directory_roles_for_activedirectory_user
    args = [self.input.user_id.value]
  }

  with "activedirectory_groups_for_activedirectory_user" {
    query = query.activedirectory_groups_for_activedirectory_user
    args = [self.input.user_id.value]
  }

  with "resource_groups_for_activedirectory_user" {
    query = query.resource_groups_for_activedirectory_user
    args = [self.input.user_id.value]
  }

  with "resource_group_role_definitions_for_activedirectory_user" {
    query = query.resource_group_role_definitions_for_activedirectory_user
    args = [self.input.user_id.value]
  }

  with "subscriptions_for_activedirectory_user" {
    query = query.subscriptions_for_activedirectory_user
    args = [self.input.user_id.value]
  }

  with "subscription_role_definitions_for_activedirectory_user" {
    query = query.subscription_role_definitions_for_activedirectory_user
    args = [self.input.user_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.activedirectory_directory_role
        args = {
          activedirectory_directory_role_ids = with.activedirectory_directory_roles_for_activedirectory_user.rows[*].directory_role_id
        }
      }

      node {
        base = node.activedirectory_group
        args = {
          activedirectory_group_ids = with.activedirectory_groups_for_activedirectory_user.rows[*].activedirectory_group_id
        }
      }

      node {
        base = node.activedirectory_user
        args = {
          activedirectory_user_ids = [self.input.user_id.value]
        }
      }

      node {
        base = node.resource_group
        args = {
          resource_group_ids = with.resource_groups_for_activedirectory_user.rows[*].resource_group_id
        }
      }

      node {
        base = node.role_definition
        args = {
          role_definition_ids = with.subscription_role_definitions_for_activedirectory_user.rows[*].role_definition_id
        }
      }

      node {
        base = node.role_definition
        args = {
          role_definition_ids = with.resource_group_role_definitions_for_activedirectory_user.rows[*].role_definition_id
        }
      }

      node {
        base = node.subscription
        args = {
          subscription_ids = with.subscriptions_for_activedirectory_user.rows[*].subscription_id
        }
      }

      edge {
        base = edge.activedirectory_group_to_activedirectory_user
        args = {
          activedirectory_group_ids = with.activedirectory_groups_for_activedirectory_user.rows[*].activedirectory_group_id
        }
      }

      edge {
        base = edge.activedirectory_user_to_activedirectory_directory_role
        args = {
          activedirectory_user_ids = [self.input.user_id.value]
        }
      }

      edge {
        base = edge.activedirectory_user_to_subscription
        args = {
          activedirectory_user_ids = [self.input.user_id.value]
        }
      }

      edge {
        base = edge.subscription_to_resource_group
        args = {
          subscription_ids = with.subscriptions_for_activedirectory_user.rows[*].subscription_id
        }
      }

      edge {
        base = edge.subscription_to_role_definition
        args = {
          role_definition_ids = with.subscription_role_definitions_for_activedirectory_user.rows[*].role_definition_id
        }
      }

      edge {
        base = edge.resource_group_to_role_definition
        args = {
          role_definition_ids = with.resource_group_role_definitions_for_activedirectory_user.rows[*].role_definition_id
        }
      }

    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.activedirectory_user_overview
      args = {
        id = self.input.user_id.value
      }

    }

    container {

      width = 6

      table {
        title = "Last 5 Sign-ins"
        query = query.activedirectory_user_sign_in_report
        args = {
          id = self.input.user_id.value
        }
      }

    }

  }

  container {

    title = "Azure Active Directory User Role Analysis"

    table {
      title = "Azure Active Directory Role Assignments"
      width = 6
      query = query.activedirectory_directory_roles_for_user
      args = {
        id = self.input.user_id.value
      }
    }

    table {
      title = "Azure Role Assignments"
      width = 6
      query = query.activedirectory_subscription_roles_for_user
      args = {
        id = self.input.user_id.value
      }
    }
  }

  table {
    title = "Groups"
    width = 12

    column "Display Name" {
      href = "${dashboard.activedirectory_group_detail.url_path}?input.group_id={{.ID | @uri}}"
    }

    query = query.activedirectory_groups_for_user
    args = {
      id = self.input.user_id.value
    }

  }

}

query "activedirectory_user_input" {
  sql = <<-EOQ
    select
      u.display_name as label,
      u.id as value,
      json_build_object(
        'Tenant', concat('tenant: ', (split_part(u.tenant_id, '-',5))::text),
        'UPN', user_principal_name
      ) as tags
    from
      azuread_user as u
    order by
      u.title;
  EOQ
}

query "activedirectory_user_type" {
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

query "activedirectory_user_overview" {
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

query "activedirectory_groups_for_user" {
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

query "activedirectory_directory_roles_for_user" {
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

query "activedirectory_subscription_roles_for_user" {
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
    order by
      role_name;
  EOQ

  param "id" {}
}

query "activedirectory_user_sign_in_report" {
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

# with queries

query "activedirectory_groups_for_activedirectory_user" {

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
      ag.id as activedirectory_group_id
    from
      group_details as ag
      left join azuread_user as au on au.id = ag.m_id
    where
      ag.tenant_id = au.tenant_id
      and au.id = $1
  EOQ
}

query "subscription_role_definitions_for_activedirectory_user" {

  sql = <<-EOQ
    select
      d.id as role_definition_id
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      (a.scope like '/subscriptions/%' and a.scope not like '%/resourceGroups/%')
      and (a.scope like '/subscriptions/%' and a.scope not like '%/resourcegroups/%')
      and d.id is not null
      and u.id = $1;
  EOQ
}

query "resource_group_role_definitions_for_activedirectory_user" {

  sql = <<-EOQ
    select
      d.id as role_definition_id,
      a.scope
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      ((a.scope like '%/resourceGroups/%')
       or (a.scope like '%/resourcegroups/%'))
       and d.id is not null
      and u.id = $1;
  EOQ
}

query "activedirectory_directory_roles_for_activedirectory_user" {

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
      r.id as directory_role_id
    from
      assigned_role as r
      left join azuread_user as au on au.id = r.m_id
    where
      r.tenant_id = au.tenant_id
      and au.id = $1;
  EOQ
}

query "subscriptions_for_activedirectory_user" {

  sql = <<-EOQ
    select
      distinct d.subscription_id as subscription_id
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      a.scope like '/subscriptions/%'
      and d.id is not null
      and u.id = $1;
  EOQ
}

query "resource_groups_for_activedirectory_user" {

  sql = <<-EOQ
    select
      r.id as resource_group_id
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
      left join azure_resource_group as r on r.name = split_part(a.scope, '/', 5)
    where
      (a.scope like '%/resourceGroups/%')
      and d.id is not null
      and r.subscription_id = d.subscription_id
      and u.id = $1;
  EOQ
}
