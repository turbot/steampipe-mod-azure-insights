edge "batch_account_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(b.id) as from_id,
      lower(a.id) as to_id
    from
      azure_batch_account as b
      join unnest($1::text[]) as i on lower(b.id) = i and b.subscription_id = split_part(i, '/', 3)
      left join azure_storage_account as a on a.id = b.auto_storage ->> 'storageAccountId';
  EOQ

  param "batch_account_ids" {}
}
