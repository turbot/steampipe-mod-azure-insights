dashboard "azure_subscription_report" {

  title         = "Azure Subscription Report"
  documentation = file("./dashboards/azure/docs/azure_subscription_report.md")

  tags = merge(local.azure_common_tags, {
    type     = "Report"
    category = "Subscriptions"
  })

  container {

    card {
      query = query.azure_subscription_count
      width = 2
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    query = query.azure_subscription_table
  }

}

query "azure_subscription_count" {
  sql = <<-EOQ
    select
      count(*) as "Subscriptions"
    from
      azure_subscription;
  EOQ
}

query "azure_subscription_table" {
  sql = <<-EOQ
    select
      subscription_id as "Subscription ID",
      tenant_id as "Tenant ID",
      display_name as "Display Name",
      state as "State",
      cloud_environment as "Cloud Environment",
      id as "ID"
    from
      azure_subscription;
  EOQ
}
