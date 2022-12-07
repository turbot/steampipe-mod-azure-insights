edge "compute_disk_encryption_set_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key_version as v
      left join azure_compute_disk_encryption_set as s on s.active_key_url = v.key_uri_with_version
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "compute_disk_to_storage_storage_account" {
  title = "blob source for disk"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_disk as d
      left join azure_storage_account as a on lower(a.id) = lower(d.creation_data_storage_account_id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

edge "compute_snapshot_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(storage_account_id) as to_id
    from
      azure_compute_snapshot
    where
      lower(storage_account_id) = any($1);
  EOQ

  param "storage_account_ids" {}
}