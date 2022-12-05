dashboard "subscription_report" {

  title         = "Azure Subscription Report"
  documentation = file("./dashboards/azure/docs/subscription_report.md")

  tags = merge(local.azure_common_tags, {
    type     = "Report"
    category = "Subscriptions"
  })

  container {

    card {
      query = query.subscription_count
      width = 2
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    query = query.subscription_table
  }

}

query "subscription_count" {
  sql = <<-EOQ
    select
      count(*) as "Subscriptions"
    from
      azure_subscription;
  EOQ
}

query "subscription_table" {
  sql = <<-EOQ
    select
      display_name as "Display Name",
      subscription_id as "Subscription ID",
      tenant_id as "Tenant ID",
      state as "State",
      cloud_environment as "Cloud Environment",
      id as "ID"
    from
      azure_subscription;
  EOQ
}
