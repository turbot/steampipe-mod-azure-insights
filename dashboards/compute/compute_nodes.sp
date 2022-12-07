node "compute_disk_encryption_set" {
  category = category.compute_disk_encryption_set

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_compute_disk_encryption_set
    where
      lower(id) = any($1);
  EOQ

  param "compute_disk_encryption_set_ids" {}
}
