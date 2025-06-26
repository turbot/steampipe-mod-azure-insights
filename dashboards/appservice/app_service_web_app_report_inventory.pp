dashboard "app_service_web_app_inventory_report" {

  title         = "Azure App Service Web App Inventory Report"
  documentation = file("./dashboards/appservice/docs/app_service_web_app_report_inventory.md")

  tags = merge(local.app_service_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {
    card {
      query = query.app_service_web_app_count
      width = 2
    }
  }

  table {
    column "Name" {
      href = "${dashboard.app_service_web_app_detail.url_path}?input.web_app_id={{.'ID' | @uri}}"
    }

    query = query.app_service_web_app_inventory_table
  }
}

query "app_service_web_app_inventory_table" {
  sql = <<-EOQ
    select
      a.name as "Name",
      a.kind as "Kind",
      a.state as "State",
      a.enabled as "Enabled",
      a.https_only as "HTTPS Only",
      a.client_cert_enabled as "Client Cert Enabled",
      a.default_site_hostname as "Default Site Hostname",
      a.host_name_disabled as "Hostname Disabled",
      a.reserved as "Reserved",
      a.tags as "Tags",
      lower(a.id) as "ID",
      sub.title as "Subscription",
      a.subscription_id as "Subscription ID",
      a.resource_group as "Resource Group",
      a.region as "Region"
    from
      azure_app_service_web_app as a,
      azure_subscription as sub
    where
      sub.subscription_id = a.subscription_id
    order by
      a.name;
  EOQ
} 