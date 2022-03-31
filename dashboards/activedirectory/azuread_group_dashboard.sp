dashboard "azuread_group_dashboard" {

  title = "Azure Active Directory Group Dashboard"
  documentation = file("./dashboards/activedirectory/docs/azuread_group_dashboard.md")

  tags = merge(local.activedirectory_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.azuread_group_count
      width = 2
    }

    card {
      query = query.azuread_security_group_count
      width = 2
    }

    card {
      query = query.azuread_microsoft_365_group_count
      width = 2
    }

    card {
      query = query.azuread_group_with_no_members_count
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Groups Without Members"
      query = query.azuread_group_with_no_member
      type  = "donut"
      width = 4

      series "count" {
        point "with members" {
          color = "ok"
        }
        point "no members" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Groups by Tenant"
      query = query.azuread_group_by_tenant
      type  = "column"
      width = 4
    }

    chart {
      title = "Groups by Type"
      query = query.azuread_group_by_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Groups by Age"
      sql   = query.azuread_group_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "azuread_group_count" {
  sql = <<-EOQ
    select count(*) as "Groups" from azuread_group;
  EOQ
}

query "azuread_security_group_count" {
  sql = <<-EOQ
    select
      count(*) as "Security Groups"
    from
      azuread_group
    where
      security_enabled;
  EOQ
}

query "azuread_microsoft_365_group_count" {
  sql = <<-EOQ
    select
      count(*) as "Microsoft 365 Groups"
    from
      azuread_group
    where
      not security_enabled;
  EOQ
}

query "azuread_group_with_no_members_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Without Members' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azuread_group
    where
      jsonb_array_length(member_ids) = 0;
  EOQ
}

# Assessment Queries

query "azuread_group_with_no_member" {
  sql = <<-EOQ
    select
      case when jsonb_array_length(member_ids) = 0  then 'no members' else 'with members' end as status,
      count(*)
    from
      azuread_group
    group by
      status;
  EOQ
}

# Analysis Queries

query "azuread_group_by_tenant" {
  sql = <<-EOQ
    with tenants as (
      select
        distinct tenant_id,
        title
      from
        azure_tenant
    )
    select
      t.title as "Tenant",
      count(g.*)
    from
      azuread_group as g,
      tenants as t
    where
      g.tenant_id = t.tenant_id
    group by
      t.title
    order by
      count desc;
  EOQ
}

query "azuread_group_by_type" {
  sql = <<-EOQ
    select
      case when security_enabled then 'Security' else 'Microsoft 365' end as type,
      count(*) as "Groups"
    from
      azuread_group
    group by
      type
    order by
      type;
  EOQ
}

query "azuread_group_by_creation_month" {
  sql = <<-EOQ
    with users as (
      select
        title,
        created_date_time,
        to_char(created_date_time,
          'YYYY-MM') as creation_month
      from
        azuread_group
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