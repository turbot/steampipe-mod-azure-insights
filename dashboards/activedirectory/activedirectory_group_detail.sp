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

  with "activedirectory_directory_roles_for_activedirectory_group" {
    query = query.activedirectory_directory_roles_for_activedirectory_group
    args  = [self.input.group_id.value]
  }

  with "activedirectory_users_for_activedirectory_group" {
    query = query.activedirectory_users_for_activedirectory_group
    args  = [self.input.group_id.value]
  }

  with "resource_groups_for_activedirectory_group" {
    query = query.resource_groups_for_activedirectory_group
    args = [self.input.group_id.value]
  }

  with "resource_group_role_definitions_for_activedirectory_group" {
    query = query.resource_group_role_definitions_for_activedirectory_group
    args = [self.input.group_id.value]
  }

  with "subscriptions_for_activedirectory_group" {
    query = query.subscriptions_for_activedirectory_group
    args  = [self.input.group_id.value]
  }

  with "subscription_role_definitions_for_activedirectory_group" {
    query = query.subscription_role_definitions_for_activedirectory_group
    args = [self.input.group_id.value]
  }

  with "target_activedirectory_groups_for_activedirectory_group" {
    query = query.target_activedirectory_groups_for_activedirectory_group
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
          activedirectory_directory_role_ids = with.activedirectory_directory_roles_for_activedirectory_group.rows[*].directory_role_id
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
          activedirectory_group_ids = with.target_activedirectory_groups_for_activedirectory_group.rows[*].activedirectory_group_id
        }
      }

      node {
        base = node.activedirectory_user
        args = {
          activedirectory_user_ids = with.activedirectory_users_for_activedirectory_group.rows[*].activedirectory_user_id
        }
      }

      node {
        base = node.resource_group
        args = {
          resource_group_ids = with.resource_groups_for_activedirectory_group.rows[*].resource_group_id
        }
      }

      node {
        base = node.role_definition
        args = {
          role_definition_ids = with.subscription_role_definitions_for_activedirectory_group.rows[*].role_definition_id
        }
      }

      node {
        base = node.role_definition
        args = {
          role_definition_ids = with.resource_group_role_definitions_for_activedirectory_group.rows[*].role_definition_id
        }
      }

      node {
        base = node.subscription
        args = {
          subscription_ids = with.subscriptions_for_activedirectory_group.rows[*].subscription_id
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
          subscription_ids = with.subscriptions_for_activedirectory_group.rows[*].subscription_id
        }
      }

      edge {
        base = edge.subscription_to_role_definition
        args = {
          role_definition_ids = with.subscription_role_definitions_for_activedirectory_group.rows[*].role_definition_id
        }
      }

      edge {
        base = edge.resource_group_to_role_definition
        args = {
          role_definition_ids = with.resource_group_role_definitions_for_activedirectory_group.rows[*].role_definition_id
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

    column "link" {
      display = "none"
    }

    column "Display Name" {
      href = "{{ .link }}"
    }

    query = query.activedirectory_group_members_attached
    args = {
      id = self.input.group_id.value
    }

  }

  table {
    title = "Owners"
    width = 12

    column "link" {
      display = "none"
    }

    column "Display Name" {
      href = "{{ .link }}"
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
      visibility as "Visibility",
      expiration_date_time as "Expiration Time",
      case when is_assignable_to_role then is_assignable_to_role else 'false' end as "Is Assignable To Role",
      mail_enabled as "Mail Enabled",
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

    -- Activedirectory Users
    select
      u.display_name as "Display Name",
      'User' as "Member Type",
      u.account_enabled as "Account Enabled",
      u.id  as "ID",
      '/azure_insights.dashboard.activedirectory_user_detail?input.user_id=' || lower(u.id) as link
    from
      azuread_group as g,
      jsonb_array_elements(member_ids) as m left join azuread_user as u on u.id = ( trim((m::text), '""'))
    where
      u.id is not null
      and g.id = $1

    -- Service Principal
    union all
    select
      s.display_name as "Display Name",
      'Service Principal' as "Member Type",
      s.account_enabled as "Account Enabled",
      s.id  as "ID",
      null as link
    from
      azuread_group as g,
      jsonb_array_elements(member_ids)as m left join  azuread_service_principal as s on s.id = ( trim((m::text), '""'))
    where
      s.id is not null
      and g.id = $1
    order by
      "Display Name";
  EOQ

  param "id" {}
}

query "activedirectory_group_owners" {
  sql = <<-EOQ

    -- Activedirectory Users
    select
      u.display_name as "Display Name",
      'User' as "Member Type",
      u.account_enabled as "Account Enabled",
      u.id  as "ID",
      '/azure_insights.dashboard.activedirectory_user_detail?input.user_id=' || lower(u.id) as link
    from
      azuread_group as g,
      jsonb_array_elements(owner_ids) as m left join azuread_user as u on u.id = (trim((m::text), '""'))
    where
      u.id is not null
      and g.id = $1

    -- Service Principal
    union all
    select
      s.display_name as "Display Name",
      'Service Principal' as "Member Type",
      s.account_enabled as "Account Enabled",
      s.id  as "ID",
      null as link
    from
      azuread_group as g,
      jsonb_array_elements(owner_ids)as m left join azuread_service_principal as s on s.id = (trim((m::text), '""'))
    where
      s.id is not null
      and g.id = $1
    order by
      "Display Name";
  EOQ

  param "id" {}
}

# with queries

query "activedirectory_users_for_activedirectory_group" {
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

query "target_activedirectory_groups_for_activedirectory_group" {

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

query "subscription_role_definitions_for_activedirectory_group" {
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

query "resource_group_role_definitions_for_activedirectory_group" {
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

query "subscriptions_for_activedirectory_group" {

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

query "activedirectory_directory_roles_for_activedirectory_group" {

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

query "resource_groups_for_activedirectory_group" {

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
