dashboard "activedirectory_group_age_report" {

  title = "Azure Active Directory Group Age Report"
  documentation = file("./dashboards/activedirectory/docs/activedirectory_group_report_age.md")


  tags = merge(local.activedirectory_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      query = query.activedirectory_group_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_group_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_group_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_group_30_90_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_group_90_365_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.activedirectory_group_1_year_count
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
      href = "${dashboard.activedirectory_group_detail.url_path}?input.group_id={{.ID | @uri}}"
    }

    query = query.activedirectory_group_age_table
  }

}

query "activedirectory_group_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azuread_group
    where
      created_date_time > now() - '1 days' :: interval;
  EOQ
}

query "activedirectory_group_30_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '1-30 Days' as label
    from
      azuread_group
    where
      created_date_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "activedirectory_group_30_90_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '30-90 Days' as label
    from
      azuread_group
    where
      created_date_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "activedirectory_group_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azuread_group
    where
      created_date_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "activedirectory_group_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azuread_group
    where
      created_date_time <= now() - '1 year' :: interval;
  EOQ
}

query "activedirectory_group_age_table" {
  sql = <<-EOQ
    select
      g.display_name as "Display Name",
      now()::date - g.created_date_time::date as "Age in Days",
      g.created_date_time as "Create Time",
      g.expiration_date_time as "Expiration Time",
      g.renewed_date_time as "Last Renewed Time",
      g.tenant_id as "Tenant ID",
      g.id as "ID"
    from
      azuread_group as g
    order by
      g.created_date_time,
      g.display_name;
  EOQ
}

