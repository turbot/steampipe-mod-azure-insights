dashboard "azure_iam_group_dashboard" {

  title = "Azure IAM Group Dashboard"
  documentation = file("./dashboards/iam/docs/iam_group_dashboard.md")

  tags = merge(local.iam_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.azure_iam_group_count
      width = 2
    }

    card {
      query = query.azure_iam_group_public_enabled_count
      width = 2
    }

    card {
      query = query.azure_iam_group_security_disabled_count
      width = 2
    }

    card {
      query = query.azure_iam_group_mail_disabled_count
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Public/Private Status"
      query = query.azure_iam_group_public_status
      type  = "donut"
      width = 2

      series "count" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Security Enabled/Disabled Status"
      query = query.azure_iam_group_security_disabled_status
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Mail Enabled/Disabled Status"
      query = query.azure_iam_group_mail_disabled_status
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Groups by Subscription"
      query = query.azure_iam_group_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Groups by Age"
      sql   = query.azure_iam_group_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "azure_iam_group_count" {
  sql = <<-EOQ
    select count(*) as "Groups" from azuread_group;
  EOQ
}

query "azure_iam_group_security_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Security Disabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azuread_group
    where
      security_enabled is not true;
  EOQ
}

query "azure_iam_group_public_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azuread_group
    where
      visibility = 'Public';
  EOQ
}

query "azure_iam_group_mail_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Mail Disabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azuread_group
    where
      mail_enabled is not true;
  EOQ
}

# Assessment Queries

query "azure_iam_group_public_status" {
  sql = <<-EOQ
    select
      case when visibility = 'Public' then 'public' else 'private' end as status,
      count(*)
    from
      azuread_group
    group by
      status;
  EOQ
}

query "azure_iam_group_security_disabled_status" {
  sql = <<-EOQ
    select
      case when security_enabled then 'enabled' else 'disabled' end as status,
      count(*)
    from
      azuread_group
    group by
      status;
  EOQ
}

query "azure_iam_group_mail_disabled_status" {
  sql = <<-EOQ
    select
      case when mail_enabled then 'enabled' else 'disabled' end as status,
      count(*)
    from
      azuread_group
    group by
      status;
  EOQ
}

# Analysis Queries

query "azure_iam_group_by_subscription" {
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

query "azure_iam_group_by_creation_month" {
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
