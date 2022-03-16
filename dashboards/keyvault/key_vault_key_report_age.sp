dashboard "azure_key_vault_key_age_report" {

  title = "Azure Key Vault Key Age Report"

  tags = merge(local.kms_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      query = query.azure_key_vault_key_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_key_vault_key_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_key_vault_key_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_key_vault_key_30_90_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_key_vault_key_90_365_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.azure_key_vault_key_1_year_count
    }

  }

  table {
    column "Subscription ID" {
      display = "none"
    }

    column "ID" {
      display = "none"
    }

    # column "Name" {
    #   href = "${dashboard.azure_key_vault_key_detail.url_path}?input.key_id={{.ID | @uri}}"
    # }

    query = query.azure_key_vault_key_age_table
  }

}

query "azure_key_vault_key_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azure_key_vault_key
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "azure_key_vault_key_30_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '1-30 Days' as label
    from
      azure_key_vault_key
    where
      created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "azure_key_vault_key_30_90_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '30-90 Days' as label
    from
      azure_key_vault_key
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "azure_key_vault_key_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azure_key_vault_key
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "azure_key_vault_key_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azure_key_vault_key
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "azure_key_vault_key_age_table" {
  sql = <<-EOQ
    select
      k.name as "Name",
      k.id as "ID",
      now()::date - k.created_at::date as "Age in Days",
      k.created_at as "Creation Date",
      k.vault_name as "Vault Name",
      k.expires_at as "Key Expiration",
      k.key_size as "Key Size",
      k.key_type as "Key Type",
      a.title as "Subscription",
      k.resource_group as "Resource Group",
      k.subscription_id as "Subscription ID",
      k.region as "Region"
    from
      azure_key_vault_key as k,
      azure_subscription as a
    where
      k.subscription_id = a.subscription_id
    order by
      k.id;
  EOQ
}
