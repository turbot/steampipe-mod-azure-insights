dashboard "azuread_user_dashboard" {

  title = "Azure Active Directory User Dashboard"
  documentation = file("./dashboards/activedirectory/docs/azuread_user_dashboard.md")

  tags = merge(local.activedirectory_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.azuread_user_count
      width = 2
    }

    #https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-external-users
    card {
      query = query.azuread_external_guest_user_count
      width = 2
    }

    card {
      query = query.azuread_user_with_custom_role_count
      width = 2
    }

    card {
      query = query.azuread_external_guest_user_with_owner_role_count
      width = 2
    }

    card {
      query = query.azuread_deprecated_user_with_owner_role_count
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "External Guest Users With Owner Role"
      query = query.azuread_external_guest_user_with_owner_role_status
      type  = "donut"
      width = 4

      series "count" {
        point "no owner role" {
          color = "ok"
        }
        point "with owner role" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Deprecated Users With Owner Role"
      query = query.azuread_deprecated_user_with_owner_status
      type  = "donut"
      width = 4

      series "count" {
        point "no owner role" {
          color = "ok"
        }
        point "with owner role" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Users by Tenant"
      query = query.azuread_user_by_tenant
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Type"
      query = query.azuread_user_by_user_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Age"
      sql   = query.azuread_user_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "azuread_user_count" {
  sql = <<-EOQ
    select count(*) as "Users" from azuread_user;
  EOQ
}

query "azuread_external_guest_user_count" {
  sql = <<-EOQ
    select
      count(*) as "External Guest Users"
    from
      azuread_user
    where
      user_type = 'Guest' or user_principal_name like '%EXT%';
  EOQ
}

query "azuread_external_guest_user_with_owner_role_count" {
  sql = <<-EOQ
    select
      count(distinct u.display_name) as value,
      'External Guest Users With Owner Role' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
      from
        azuread_user as u
        left join azure_role_assignment as a on a.principal_id = u.id
        left join azure_role_definition as d on d.id = a.role_definition_id
      where d.role_name = 'Owner'
        and (u.user_principal_name like '%EXT%' or user_type = 'Guest' );
  EOQ
}

query "azuread_deprecated_user_with_owner_role_count" {
  sql = <<-EOQ
    select
      count(distinct
      u.display_name) as value,
      'Deprecated Users With Owner Role' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
      where d.role_name = 'Owner' and not u.account_enabled;
  EOQ
}

query "azuread_user_with_custom_role_count" {
  sql = <<-EOQ
    select
      count(distinct
      u.display_name) as value,
      'With Custom Role' as label
    from
      azuread_user as u
      left join azure_role_assignment as a on a.principal_id = u.id
      left join azure_role_definition as d on d.id = a.role_definition_id
      where d.role_type = 'CustomRole' and  u.account_enabled;
  EOQ
}

# Assessment Queries

query "azuread_deprecated_user_with_owner_status" {
  sql = <<-EOQ
    with deprecated_account as (
      select
        distinct u.display_name,
        u.id
      from
        azuread_user as u
        left join azure_role_assignment as a on a.principal_id = u.id
        left join azure_role_definition as d on d.id = a.role_definition_id
        where d.role_name = 'Owner' and not u.account_enabled
    ), deprecated_account_status as (
    select
      case when dp.id is not null then 'with owner role' else 'no owner role' end as deprecated_account_status
    from
      azuread_user as u left join deprecated_account as dp on u.id = dp.id
    where
      not u.account_enabled
    )
    select
      deprecated_account_status,
      count(*)
    from
      deprecated_account_status
    group by
      deprecated_account_status;
  EOQ
}

query "azuread_external_guest_user_with_owner_role_status" {
  sql = <<-EOQ
    with external_guest_user_with_owner_role as (
      select
        distinct u.id,
        d.role_name,
        u.account_enabled,
        u.user_principal_name,
        d.subscription_id
      from
        azuread_user as u
        left join azure_role_assignment as a on a.principal_id = u.id
        left join azure_role_definition as d on d.id = a.role_definition_id
      where
        d.role_name = 'Owner'
        and (u.user_principal_name like '%EXT%' or user_type = 'Guest')
    )
    select
      case when u.id in (select  id  from external_guest_user_with_owner_role ) then 'with owner role' else 'no owner role' end as status,
      count(*)
    from
      azuread_user as u
    where
      u.user_principal_name like '%EXT%'
    group by
      status;
  EOQ
}

# Analysis Queries

query "azuread_user_by_tenant" {
  sql = <<-EOQ
    select
      t.title as "Tenant",
      count(u.*)
    from
      azuread_user as u,
      azure_tenant as t
    where
      u.tenant_id = t.tenant_id
    group by
      t.title
    order by
      count desc;
  EOQ
}

query "azuread_user_by_user_type" {
  sql = <<-EOQ
    select
      user_type as "User Type",
      count(user_type) as "Users"
    from
      azuread_user
    group by
      user_type
    order by
      user_type;
  EOQ
}

query "azuread_user_by_creation_month" {
  sql = <<-EOQ
    with users as (
      select
        title,
        created_date_time,
        to_char(created_date_time,
          'YYYY-MM') as creation_month
      from
        azuread_user
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_date_time)
                from users)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    users_by_month as (
      select
        creation_month,
        count(*)
      from
        users
      group by
        creation_month
    )
    select
      months.month,
      users_by_month.count
    from
      months
      left join users_by_month on months.month = users_by_month.creation_month
    order by
      months.month;
  EOQ
}