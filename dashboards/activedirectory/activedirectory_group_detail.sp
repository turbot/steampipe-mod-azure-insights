dashboard "activedirectory_group_detail" {

  title         = "Azure Active Directory Group Detail"
  documentation = file("./dashboards/activedirectory/docs/activedirectory_group_detail.md")

  tags = merge(local.activedirectory_common_tags, {
    type = "Detail"
  })

  input "group_id" {
    title = "Select a group:"
    sql   = query.activedirectory_group_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.activedirectory_group_type
      args = {
        id = self.input.group_id.value
      }
    }

    card {
      width = 2
      query = query.activedirectory_group_members_attached_count
      args = {
        id = self.input.group_id.value
      }
    }

  }

  with "activedirectory_directory_roles" {
    query = query.activedirectory_group_activedirectory_directory_role
    args  = [self.input.group_id.value]
  }

  with "activedirectory_users" {
    query = query.activedirectory_group_activedirectory_users
    args  = [self.input.group_id.value]
  }

  with "resource_groups" {
    query = query.activedirectory_group_resource_groups
    args  = [self.input.group_id.value]
  }

  with "resource_group_role_definitions" {
    query = query.activedirectory_group_resource_group_role_definitions
    args  = [self.input.group_id.value]
  }

  with "subscriptions" {
    query = query.activedirectory_group_subscriptions
    args  = [self.input.group_id.value]
  }

  with "subscription_role_definitions" {
    query = query.activedirectory_group_subscription_role_definitions
    args  = [self.input.group_id.value]
  }

  with "to_activedirectory_groups" {
    query = query.activedirectory_group_activedirectory_groups
    args  = [self.input.group_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.activedirectory_directory_role
        args = {
          activedirectory_directory_role_ids = with.activedirectory_directory_roles.rows[*].directory_role_id
        }
      }

      node {
        base = node.activedirectory_group
        args = {
          activedirectory_group_ids = [self.input.group_id.value]
        }
      }

      node {
        base = node.activedirectory_group
        args = {
          activedirectory_group_ids = with.to_activedirectory_groups.rows[*].activedirectory_group_id
        }
      }

      node {
        base = node.activedirectory_user
        args = {
          activedirectory_user_ids = with.activedirectory_users.rows[*].activedirectory_user_id
        }
      }

      node {
        base = node.resource_group
        args = {
          resource_group_ids = with.resource_groups.rows[*].resource_group_id
        }
      }

      node {
        base = node.role_definition
        args = {
          role_definition_ids = with.subscription_role_definitions.rows[*].role_definition_id
        }
      }

      node {
        base = node.role_definition
        args = {
          role_definition_ids = with.resource_group_role_definitions.rows[*].role_definition_id
        }
      }

      node {
        base = node.subscription
        args = {
          subscription_ids = with.subscriptions.rows[*].subscription_id
        }
      }

      edge {
        base = edge.activedirectory_group_to_activedirectory_user
        args = {
          activedirectory_group_ids = [self.input.group_id.value]
        }
      }

      edge {
        base = edge.activedirectory_group_to_activedirectory_directory_role
        args = {
          activedirectory_group_ids = [self.input.group_id.value]
        }
      }

      edge {
        base = edge.activedirectory_group_to_activedirectory_group
        args = {
          activedirectory_group_ids = [self.input.group_id.value]
        }
      }

      edge {
        base = edge.activedirectory_group_to_subscription
        args = {
          activedirectory_group_ids = [self.input.group_id.value]
        }
      }

      edge {
        base = edge.subscription_to_resource_group
        args = {
          subscription_ids = with.subscriptions.rows[*].subscription_id
        }
      }

      edge {
        base = edge.subscription_to_role_definition
        args = {
          role_definition_ids = with.subscription_role_definitions.rows[*].role_definition_id
        }
      }

      edge {
        base = edge.resource_group_to_role_definition
        args = {
          role_definition_ids = with.resource_group_role_definitions.rows[*].role_definition_id
        }
      }

    }
  }

  container {

    container {

      title = "Overview"

      table {
        type  = "line"
        width = 6
        query = query.activedirectory_group_overview
        args = {
          id = self.input.group_id.value
        }

      }

      table {
        title = "Directory Roles"
        width = 6
        query = query.activedirectory_group_directory_roles
        args = {
          id = self.input.group_id.value
        }

      }

    }

  }

  table {
    title = "Members"
    width = 12
    column "Display Name" {
      // cyclic dependency prevents use of url_path, hardcode for now
      //href = "${dashboard.azuread_user_detail.url_path}?input.user_id={{.ID | @uri}}"
      href = "/azure_insights.dashboard.activedirectory_user_detail?input.user_id={{.ID | @uri}}"
    }
    query = query.activedirectory_group_members_attached
    args = {
      id = self.input.group_id.value
    }

  }

  table {
    title = "Owners"
    width = 12
    column "Display Name" {
      // cyclic dependency prevents use of url_path, hardcode for now
      //href = "${dashboard.azuread_user_detail.url_path}?input.user_id={{.ID | @uri}}"
      href = "/azure_insights.dashboard.activedirectory_user_detail?input.user_id={{.ID | @uri}}"
    }
    query = query.activedirectory_group_owners
    args = {
      id = self.input.group_id.value
    }

  }

}

query "activedirectory_group_input" {
  sql = <<-EOQ
    select
      g.title as label,
      g.id as value,
      json_build_object(
        'tenant', concat('tenant: ', (split_part(g.tenant_id, '-',5))::text),
         'group_id', concat('id: ', (split_part(g.id, '-',5))::text)
      ) as tags
    from
      azuread_group as g
    order by
      g.title;
  EOQ
}

query "activedirectory_group_type" {
  sql = <<-EOQ
    select
      'Group Type' as label,
      case when security_enabled then 'Security' else 'Microsoft 365' end as value
    from
      azuread_group
    where
      id = $1;
  EOQ

  param "id" {}
}

query "activedirectory_group_members_attached_count" {
  sql = <<-EOQ
    select
      'Attached Members' as label,
      jsonb_array_length(member_ids) as value,
      case when jsonb_array_length(member_ids) = 0 then 'alert' else 'ok' end as type
    from
      azuread_group
    where
      id = $1;
  EOQ

  param "id" {}
}

query "activedirectory_group_overview" {
  sql = <<-EOQ
    select
      display_name as "Display Name",
      created_date_time as "Create Time",
      expiration_date_time as "Expiration Time",
      is_assignable_to_role as "Is Assignable To Role",
      is_subscribed_by_mail as "Is Subscribed By Mail",
      visibility as "Visibility",
      tenant_id as "Tenant ID",
      id as "ID"
    from
      azuread_group
    where
      id = $1;
  EOQ

  param "id" {}
}

query "activedirectory_group_directory_roles" {
  sql = <<-EOQ
    select
      dr.display_name as "Display Name",
      dr.id as "ID"
    from
      azuread_directory_role as dr,
      jsonb_array_elements(member_ids) as m
    where
      trim((m::text), '""') = $1
    order by
      dr.display_name;
  EOQ

  param "id" {}
}

query "activedirectory_group_members_attached" {
  sql = <<-EOQ
    select
      case when u.display_name is not null then u.display_name else s.display_name end as "Display Name",
      case when u.display_name is not null then 'User' else 'Service Principal' end as "Member Type",
      case when u.account_enabled is not null then u.account_enabled else s.account_enabled end as "Account Enabled",
      case when u.id is not null then u.id else s.id end as "ID"
    from
      azuread_group as g,
      jsonb_array_elements(member_ids) as m left join azuread_user as u on u.id = ( trim((m::text), '""')) left join  azuread_service_principal as s on s.id = ( trim((m::text), '""'))
    where
      g.id = $1
    order by
      u.display_name;
  EOQ

  param "id" {}
}

query "activedirectory_group_owners" {
  sql = <<-EOQ
    select
      case when u.display_name is not null then u.display_name else s.display_name end as "Display Name",
      case when u.display_name is not null then 'User' else 'Service Principal' end as "Member Type",
      case when u.account_enabled is not null then u.account_enabled else s.account_enabled end as "Account Enabled",
      case when u.id is not null then u.id else s.id end as "ID"
    from
      azuread_group as g,
      jsonb_array_elements(owner_ids) as m left join azuread_user as u on u.id = ( trim((m::text), '""')) left join  azuread_service_principal as s on s.id = ( trim((m::text), '""'))
    where
      g.id = $1
    order by
      u.display_name;
  EOQ

  param "id" {}
}

query "activedirectory_group_activedirectory_users" {
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
      au.id as activedirectory_user_id
    from
      group_details as ag
      left join azuread_user as au on ag.m_id = au.id
    where
      au.id is not null
      and ag.id = $1
  EOQ

}

query "activedirectory_group_activedirectory_groups" {

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
      g.id as activedirectory_group_id
    from
      group_details as ag
      left join azuread_group as g on ag.m_id = g.id
    where
      g.id is not null
      and ag.id = $1;
  EOQ

}

query "activedirectory_group_subscription_role_definitions" {
  sql = <<-EOQ
    select
      d.id as role_definition_id
    from
      azuread_group as g
      left join azure_role_assignment as a on a.principal_id = g.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      (a.scope like '/subscriptions/%' and a.scope not like '%/resourceGroups/%')
      and (a.scope like '/subscriptions/%' and a.scope not like '%/resourcegroups/%')
      and  d.id is not null
      and g.id = $1
  EOQ

}

query "activedirectory_group_resource_group_role_definitions" {
  sql = <<-EOQ
    select
      d.id as role_definition_id
    from
      azuread_group as g
      left join azure_role_assignment as a on a.principal_id = g.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      ((a.scope like '%/resourceGroups/%')
      or (a.scope like '%/resourcegroups/%'))
      and  d.id is not null
      and g.id = $1
  EOQ

}

query "activedirectory_group_subscriptions" {
  sql = <<-EOQ
    select
      distinct d.subscription_id as subscription_id
    from
      azuread_group as g
      left join azure_role_assignment as a on a.principal_id = G.id
      left join azure_role_definition as d on d.id = a.role_definition_id
    where
      a.scope like '/subscriptions/%'
      and d.id is not null
      and g.id = $1
  EOQ

}

query "activedirectory_group_activedirectory_directory_role" {
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
      left join azuread_group as g on g.id = r.m_id
    where
      r.tenant_id = g.tenant_id
      and g.id = $1;
  EOQ

}

query "activedirectory_group_resource_groups" {

  sql = <<-EOQ
    select
      r.id as resource_group_id
    from
      azuread_group as g
      left join azure_role_assignment as a on a.principal_id = g.id
      left join azure_role_definition as d on d.id = a.role_definition_id
      left join azure_resource_group as r on r.name = split_part(a.scope, '/', 5)
    where
      (a.scope like '%/resourceGroups/%')
      and d.id is not null
      and r.subscription_id = d.subscription_id
      and g.id = $1
  EOQ

}
