dashboard "azure_sql_server_encryption_report" {

  title         = "Azure SQL Server Encryption Report"

  tags = merge(local.sql_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.azure_sql_server_count
      width = 2
    }

    card {
      query = query.azure_sql_server_default_encrypted_servers_count
      width = 2
    }

    card {
      query = query.azure_sql_server_customer_managed_encryption_count
      width = 2
    }

  }

  table {
    column "ID" {
      display = "none"
    }

    column "Subscription ID" {
      display = "none"
    }

    query = query.azure_sql_server_encryption_report
  }

}

query "azure_sql_server_encryption_report" {
  sql = <<-EOQ
    with encryption_protector as (
      select
        id ,
        ep ->> 'kind' as kind,
        ep ->> 'serverKeyName' as serverKeyName,
        ep ->> 'serverKeyType' as serverKeyType
      from
        azure_sql_server,
        jsonb_array_elements(encryption_protector) as ep
    )
    select
      s.name as "Name",
      s.id as "ID",
      e.kind as "Kind",
      e.serverKeyName as "Server Key Name",
      e.serverKeyType as "Server Key Type",
      s.subscription_id as "Subscription ID",
      sub.title as "Subscription",
      s.region as "Region",
      s.resource_group as "Resource Group"
    from
      azure_sql_server as s left join encryption_protector as e on s.id = e.id,
      azure_subscription sub
    where
      sub.subscription_id = s.subscription_id;
  EOQ
}
