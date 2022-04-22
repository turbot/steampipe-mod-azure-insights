dashboard "azuread_group_detail" {

  title = "Azure Active Directory Group Detail"
  documentation = file("./dashboards/activedirectory/docs/azuread_group_detail.md")

  tags = merge(local.activedirectory_common_tags, {
    type = "Detail"
  })

  input "group_id" {
    title = "Select a group:"
    sql   = query.azuread_group_input.sql
    width = 2
  }

  container {

    card {
      width = 2
      query = query.azuread_group_type
      args  = {
        id = self.input.group_id.value
      }
    }

    card {
      width = 2
      query = query.azuread_group_members_attached_count
      args  = {
        id = self.input.group_id.value
      }
    }

  }

  container {

    container {

      title = "Overview"

      table {
        type  = "line"
        width = 6
        query = query.azuread_group_overview
        args  = {
          id = self.input.group_id.value
        }

      }

      table {
        title = "Directory Roles"
        width = 6
        query = query.azuread_group_directory_roles
        args  = {
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
      href = "/azure_insights.dashboard.azuread_user_detail?input.user_id={{.ID | @uri}}"
    }
    query = query.azuread_group_members_attached
    args  = {
      id = self.input.group_id.value
    }

  }

  table {
    title = "Owners"
    width = 12
    column "Display Name" {
      // cyclic dependency prevents use of url_path, hardcode for now
      //href = "${dashboard.azuread_user_detail.url_path}?input.user_id={{.ID | @uri}}"
      href = "/azure_insights.dashboard.azuread_user_detail?input.user_id={{.ID | @uri}}"
    }
    query = query.azuread_group_owners
    args  = {
      id = self.input.group_id.value
    }

  }

}

query "azuread_group_input" {
  sql = <<-EOQ
    with tenants as (
      select
        distinct tenant_id,
        name
      from
        azure_tenant
    )
    select
      g.title as label,
      g.id as value,
      json_build_object(
        'tenanat', t.name
      ) as tags
    from
      azuread_group as g,
      tenants as t
    where
      g.tenant_id = t.tenant_id
    order by
      g.title;
  EOQ
}

query "azuread_group_type" {
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

query "azuread_group_members_attached_count" {
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

query "azuread_group_overview" {
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

query "azuread_group_directory_roles" {
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

query "azuread_group_members_attached" {
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

query "azuread_group_owners" {
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
