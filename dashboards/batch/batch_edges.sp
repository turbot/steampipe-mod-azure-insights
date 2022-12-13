edge "batch_account_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(b.id) as from_id,
      lower(a.id) as to_id
    from
      azure_batch_account as b
      left join azure_storage_account as a on a.id = b.auto_storage ->> 'storageAccountId'
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}
