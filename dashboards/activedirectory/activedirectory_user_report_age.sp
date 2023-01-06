dashboard "activedirectory_user_age_report" {

  title = "Azure Active Directory User Age Report"
  documentation = file("./dashboards/activedirectory/docs/activedirectory_user_report_age.md")


  tags = merge(local.activedirectory_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      query = query.activedirectory_user_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_user_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_user_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_user_30_90_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_user_90_365_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_user_1_year_count
    }

  }

  table {
    column "Tenant ID" {
      display = "none"
    }

    column "ID" {
      display = "none"
    }

    column "Display Name" {
      href = "${dashboard.activedirectory_user_detail.url_path}?input.user_id={{.ID | @uri}}"
    }

    query = query.activedirectory_user_age_table
  }

}

query "activedirectory_user_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azuread_user
    where
      created_date_time > now() - '1 days' :: interval;
  EOQ
}

query "activedirectory_user_30_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '1-30 Days' as label
    from
      azuread_user
    where
      created_date_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "activedirectory_user_30_90_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '30-90 Days' as label
    from
      azuread_user
    where
      created_date_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "activedirectory_user_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azuread_user
    where
      created_date_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "activedirectory_user_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azuread_user
    where
      created_date_time <= now() - '1 year' :: interval;
  EOQ
}

query "activedirectory_user_age_table" {
  sql = <<-EOQ
    select
      u.display_name as "Display Name",
      u.given_name as "Given Name",
      now()::date - u.created_date_time::date as "Age in Days",
      u.created_date_time as "Create Time",
      u.user_type as "User Type",
      u.tenant_id as "Tenant ID",
      u.id as "ID"
    from
      azuread_user as u
    order by
      u.display_name;
  EOQ
}
