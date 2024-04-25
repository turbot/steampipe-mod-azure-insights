
node "storage_storage_account" {
  category = category.storage_storage_account

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_storage_account
      join unnest($1::text[]) as i on lower(id) = i and subscription_id = split_part(i, '/', 3);
  EOQ

  param "storage_account_ids" {}
}

node "storage_storage_container" {
  category = category.storage_container

  sql = <<-EOQ
    select
      lower(c.id) as id,
      c.title as title,
      jsonb_build_object(
        'Name', c.name,
        'ID', c.id,
        'Type', c.type,
        'Resource Group', c.resource_group,
        'Subscription ID', c.subscription_id
      ) as properties
    from
      azure_storage_container as c
      left join azure_storage_account as a on a.name = c.account_name
      and a.resource_group = c.resource_group
      and a.subscription_id = c.subscription_id
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

node "storage_storage_queue" {
  category = category.storage_queue

  sql = <<-EOQ
    select
      lower(q.id) as id,
      q.title as title,
      jsonb_build_object(
        'Name', q.name,
        'ID', q.id,
        'Region', q.region,
        'Type', q.type,
        'Resource Group', q.resource_group,
        'Subscription ID', q.subscription_id
      ) as properties
    from
      azure_storage_account as a
      left join azure_storage_queue as q on q.storage_account_name = a.name
      and a.resource_group = q.resource_group
      and a.subscription_id = q.subscription_id
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

node "storage_storage_share_file" {
  category = category.storage_share_file

  sql = <<-EOQ
    select
      lower(f.id) as id,
      f.title as title,
      jsonb_build_object(
        'Name', f.name,
        'ID', f.id,
        'Type', f.type,
        'Resource Group', f.resource_group,
        'Subscription ID', f.subscription_id
      ) as properties
    from
      azure_storage_share_file as f
      left join azure_storage_account as a on a.name = f.storage_account_name
      and a.resource_group = f.resource_group
      and a.subscription_id = f.subscription_id
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

node "storage_storage_table" {
  category = category.storage_table

  sql = <<-EOQ
    select
      lower(t.id) as id,
      t.title as title,
      jsonb_build_object(
        'Name', t.name,
        'ID', t.id,
        'Type', t.type,
        'Region', t.region,
        'Resource Group', t.resource_group,
        'Subscription ID', t.subscription_id
      ) as properties
    from
      azure_storage_account as a
      left join azure_storage_table as t on t.storage_account_name = a.name
      and a.resource_group = t.resource_group
      and a.subscription_id = t.subscription_id
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}