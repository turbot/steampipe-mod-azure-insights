dashboard "cosmosdb_account_encryption_report" {

  title         = "Azure CosmosDB Account Encryption Report"
  documentation = file("./dashboards/cosmosdb/docs/cosmosdb_account_report_encryption.md")

  tags = merge(local.cosmosdb_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.cosmosdb_account_count
      width = 3
    }

    card {
      query = query.cosmosdb_account_default_encrypted_servers_count
      width = 3
    }

    card {
      query = query.cosmosdb_account_customer_managed_encryption_count
      width = 3
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "Key ID" {
      display = "none"
    }

    column "Account Name" {
      href = "${dashboard.cosmosdb_account_detail.url_path}?input.cosmosdb_account_id={{.'Account ID' | @uri}}"
    }

    column "Account Key Name" {
      href = "{{ if .'Account Key Name' == '' then null else '${dashboard.key_vault_detail.url_path}?input.key_vault_id=' + (.'Account Key Name' | @uri) end }}"
    }

    column "Subscription ID" {
      display = "none"
    }

    query = query.cosmosdb_account_encryption_report
  }

}

query "cosmosdb_account_encryption_report" {
  sql = <<-EOQ
    select
      a.name as "Account Name",
      a.kind as "Kind",
      k.name as "Key Name",
      case when a.key_vault_key_uri is null then 'Platform-Managed' else 'Customer Managed' end as "Account Key Type",
      s.title as "Subscription",
      a.subscription_id as "Subscription ID",
      a.resource_group as "Resource Group",
      a.region as "Region",
      lower(a.id) as "Account ID",
      lower(k.id) as "Key ID"
    from
      azure_cosmosdb_account as a
        left join azure_key_vault_key as k 
        on a.key_vault_key_uri = k.key_uri,
      azure_subscription as s
    where
      s.subscription_id = a.subscription_id;
  EOQ
}

query "cosmosdb_account_default_encrypted_servers_count" {
  sql = <<-EOQ
    select
      count(*) as "Platform-Managed Encryption"
    from
      azure_cosmosdb_account
    where
      key_vault_key_uri is null
  EOQ
}

query "cosmosdb_account_customer_managed_encryption_count" {
  sql = <<-EOQ
   select
      count(*) as "Customer-Managed Encryption"
    from
      azure_cosmosdb_account
    where
      key_vault_key_uri is not null
  EOQ
}
