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
      query = query.azuread_group_with_no_members_count
      width = 2
    }

  }

  container {
    title = "Assessments"

  }

  container {
    title = "Analysis"

    chart {
      title = "Groups by Subscription"
      query = query.azuread_group_by_subscription
      type  = "column"
      width = 3
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

query "azuread_group_with_no_members_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'With No Members' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azuread_group
    where
      jsonb_array_length(member_ids) = 0;
  EOQ
}

# Assessment Queries

# Analysis Queries

query "azuread_group_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(g.*)
    from
      azuread_group as g,
      azure_subscription as sub
    where
      g.tenant_id = sub.tenant_id
    group by
      sub.title
    order by
      count desc;
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