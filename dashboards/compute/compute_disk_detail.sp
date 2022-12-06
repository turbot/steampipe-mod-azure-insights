dashboard "compute_disk_detail" {

  title         = "Azure Compute Disk Detail"
  documentation = file("./dashboards/compute/docs/compute_disk_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "disk_id" {
    title = "Select a disk:"
    query = query.compute_disk_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.compute_disk_size
      args = {
        id = self.input.disk_id.value
      }
    }

    card {
      width = 2
      query = query.compute_disk_os_type
      args = {
        id = self.input.disk_id.value
      }
    }

    card {
      width = 2
      query = query.compute_disk_sku_name
      args = {
        id = self.input.disk_id.value
      }
    }

    card {
      width = 2
      query = query.compute_disk_status
      args = {
        id = self.input.disk_id.value
      }
    }

    card {
      width = 2
      query = query.compute_disk_network_access_policy
      args = {
        id = self.input.disk_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "virtual_machines" {
        sql = <<-EOQ
          select
            lower(m.id) as virtual_machine_id
          from
            azure_compute_virtual_machine as m,
            jsonb_array_elements(data_disks) as data_disk
          where
            lower(data_disk -> 'managedDisk' ->> 'id') = lower($1)
            or lower(m.managed_disk_id) = $1;
          EOQ

        args = [self.input.disk_id.value]
      }

      with "key_vaults" {
        sql = <<-EOQ
          select
            lower(k.id) as key_vault_id
          from
            azure_compute_disk_encryption_set as e
            left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
            left join azure_key_vault as k on lower(e.active_key_source_vault_id) = lower(k.id)
          where
            lower(d.id) = $1;
          EOQ

        args = [self.input.disk_id.value]
      }

      with "key_vault_keys" {
        sql = <<-EOQ
          select
            lower(k.id) as key_vault_key_id
          from
            azure_compute_disk_encryption_set as e
            left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
            left join azure_key_vault_key_version as v on lower(e.active_key_url) = lower(v.key_uri_with_version)
            left join azure_key_vault_key as k on lower(k.key_uri) = lower(v.key_uri)
          where
            lower(d.id) = $1;
          EOQ

        args = [self.input.disk_id.value]
      }

      with "compute_snapshots" {
        sql = <<-EOQ
          select
            lower(s.id) as compute_snapshot_id
          from
            azure_compute_disk as d
            left join azure_compute_snapshot as s on lower(s.source_resource_id) = lower(d.id)
          where
            s.id is not null
            and lower(d.id) = $1
          union
          select
            lower(s.id) as compute_snapshot_id
          from
            azure_compute_disk as d
            left join azure_compute_snapshot as s on lower(s.id) = lower(d.creation_data_source_resource_id)
          where
            s.id is not null
            and lower(d.id) = $1
          EOQ

        args = [self.input.disk_id.value]
      }

      with "storage_accounts" {
        sql = <<-EOQ
          select
            lower(a.id) as storage_account_id
          from
            azure_compute_disk as d
            left join azure_storage_account as a on lower(a.id) = lower(d.creation_data_storage_account_id)
          where
            d.creation_data_storage_account_id is not null
            and lower(d.id) = $1
          EOQ

        args = [self.input.disk_id.value]
      }

      nodes = [
        node.compute_disk_compute_disk_access,
        node.compute_disk_compute_disk_encryption_set,
        node.compute_disk_to_compute_disk,
        node.compute_disk,
        node.compute_snapshot,
        node.compute_virtual_machine,
        node.key_vault_key,
        node.key_vault,
        node.storage_storage_account,
      ]

      edges = [
        edge.compute_disk_compute_to_key_vault,
        edge.compute_disk_to_compute_disk_access,
        edge.compute_disk_to_compute_disk_encryption_set,
        edge.compute_disk_to_compute_disk,
        edge.compute_disk_to_compute_snapshot,
        edge.compute_disk_to_key,
        edge.compute_disk_to_storage_storage_account,
        edge.compute_snapshot_to_compute_disk,
        edge.compute_virtual_machine_to_compute_disk,
      ]

      args = {
        compute_disk_ids            = [self.input.disk_id.value]
        compute_snapshot_ids        = with.compute_snapshots.rows[*].compute_snapshot_id
        compute_virtual_machine_ids = with.virtual_machines.rows[*].virtual_machine_id
        key_vault_ids               = with.key_vaults.rows[*].key_vault_id
        key_vault_key_ids           = with.key_vault_keys.rows[*].key_vault_key_id
        storage_account_ids         = with.storage_accounts.rows[*].storage_account_id
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.compute_disk_overview
        args = {
          id = self.input.disk_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_disk_tags
        args = {
          id = self.input.disk_id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Attached To"
        query = query.compute_disk_associated_virtual_machine_details
        args = {
          id = self.input.disk_id.value
        }

        column "Name" {
          href = "${dashboard.compute_virtual_machine_detail.url_path}?input.vm_id={{.ID | @uri}}"
        }
      }

      table {
        title = "Disk Encryption Set"
        query = query.compute_disk_encryption_set_details
        args = {
          id = self.input.disk_id.value
        }

        column "Key Vault ID" {
          display = "none"
        }

        column "Key ID" {
          display = "none"
        }

        column "Key Vault Name" {
          href = "${dashboard.key_vault_detail.url_path}?input.key_vault_id={{.'Key Vault ID' | @uri}}"
        }

        column "Key Name" {
          href = "${dashboard.key_vault_key_detail.url_path}?input.key_vault_key_id={{.'Key ID' | @uri}}"
        }
      }
    }

  }

}

query "compute_disk_input" {
  sql = <<-EOQ
    select
      d.title as label,
      lower(d.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', d.resource_group,
        'region', d.region
      ) as tags
    from
      azure_compute_disk as d,
      azure_subscription as s
    where
      lower(d.subscription_id) = lower(s.subscription_id)
    order by
      d.title;
  EOQ
}

query "compute_disk_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      disk_state as value,
      case when disk_state = 'Attached' then 'ok' else 'alert' end as type
    from
      azure_compute_disk
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "compute_disk_network_access_policy" {
  sql = <<-EOQ
    select
      'Network Access Policy' as label,
      network_access_policy as value,
      case when network_access_policy = 'AllowAll' then 'alert' else 'ok' end as type
    from
      azure_compute_disk
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "compute_disk_size" {
  sql = <<-EOQ
    select
      'Size (GB)' as label,
      disk_size_gb as value
    from
      azure_compute_disk
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_disk_os_type" {
  sql = <<-EOQ
    select
      'OS Type' as label,
      case when  os_type = '' then 'NA' else os_type end as value
    from
      azure_compute_disk
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_disk_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_compute_disk
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

node "compute_disk" {
  category = category.compute_disk

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Provisioning State', provisioning_state,
        'OS Type', os_type,
        'Region', region
      ) as properties
    from
      azure_compute_disk
    where
      lower(id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "azure_compute_disk_from_compute_virtual_machine_node" {
  category = category.compute_virtual_machine

  sql = <<-EOQ
    select
      lower(m.id) as id,
      m.title as title,
      jsonb_build_object(
        'Name', m.name,
        'ID', m.id,
        'Subscription ID', m.subscription_id,
        'Resource Group', m.resource_group,
        'Region', m.region
      ) as properties
    from
      azure_compute_virtual_machine as m,
      jsonb_array_elements(data_disks) as data_disk
    where
      lower(data_disk -> 'managedDisk' ->> 'id') = lower($1)
      or lower(m.managed_disk_id) = lower($1);
  EOQ

  param "id" {}
}

edge "compute_virtual_machine_to_compute_disk" {
  title = "disk"

  sql = <<-EOQ
    select
      lower(m.id) as from_id,
      case when lower(data_disk -> 'managedDisk' ->> 'id') = any($1) then lower(data_disk -> 'managedDisk' ->> 'id') else lower(m.managed_disk_id) end as to_id
    from
      azure_compute_virtual_machine as m,
      jsonb_array_elements(data_disks) as data_disk
    where
      lower(data_disk -> 'managedDisk' ->> 'id') = any($1)
      or lower(m.managed_disk_id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "compute_disk_compute_disk_access" {
  category = category.compute_disk_access

  sql = <<-EOQ
    select
      lower(a.id) as id,
      a.title as title,
      jsonb_build_object(
        'Name', a.name,
        'ID', a.id,
        'Type', a.type,
        'Provisioning State', a.provisioning_state,
        'Subscription ID', a.subscription_id,
        'Resource Group', a.resource_group,
        'Region', a.region
      ) as properties
    from
      azure_compute_disk_access as a
      left join azure_compute_disk as d on lower(d.disk_access_id) = lower(a.id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

edge "compute_disk_to_compute_disk_access" {
  title = "disk access"

  sql = <<-EOQ
    select
      lower(d.id) as from_id,
      lower(a.id) as to_id
    from
      azure_compute_disk_access as a
      left join azure_compute_disk as d on lower(d.disk_access_id) = lower(a.id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "compute_disk_compute_disk_encryption_set" {
  category = category.compute_disk_encryption_set

  sql = <<-EOQ
    select
      lower(e.id) as id,
      e.title as title,
      jsonb_build_object(
        'Name', e.name,
        'ID', e.id,
        'Subscription ID', e.subscription_id,
        'Resource Group', e.resource_group,
        'Region', e.region
      ) as properties
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

edge "compute_disk_to_compute_disk_encryption_set" {
  title = "disk encryption set"

  sql = <<-EOQ
    select
      lower(d.id) as from_id,
      lower(e.id) as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "azure_compute_disk_compute_disk_encryption_set_to_key_vault_node" {
  category = category.key_vault

  sql = <<-EOQ
    select
      lower(k.id) as id,
      k.title as title,
      jsonb_build_object(
        'Name', k.name,
        'ID', k.id,
        'Subscription ID', k.subscription_id,
        'Resource Group', k.resource_group,
        'Region', k.region
      ) as properties
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault as k on lower(e.active_key_source_vault_id) = lower(k.id)
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "compute_disk_compute_to_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(e.id) as from_id,
      lower(k.id) as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault as k on lower(e.active_key_source_vault_id) = lower(k.id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "azure_compute_disk_compute_disk_encryption_set_key_vault_to_key_node" {
  category = category.key_vault_key

  sql = <<-EOQ
    select
      lower(k.id) as id,
      k.title as title,
      jsonb_build_object(
        'Name', k.name,
        'Key ID', k.id,
        'Subscription ID', k.subscription_id,
        'Resource Group', k.resource_group,
        'Region', k.region
      ) as properties
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault_key_version as v on lower(e.active_key_url) = lower(v.key_uri_with_version)
      left join azure_key_vault_key as k on lower(k.key_uri) = lower(v.key_uri)
    where
      lower(d.id) = lower($1);
  EOQ

  param "id" {}
}

edge "compute_disk_to_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(e.active_key_source_vault_id) as from_id,
      lower(k.id) as to_id
     from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault_key_version as v on lower(e.active_key_url) = lower(v.key_uri_with_version)
      left join azure_key_vault_key as k on lower(k.key_uri) = lower(v.key_uri)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "azure_compute_disk_from_compute_snapshot_node" {
  category = category.compute_snapshot

  sql = <<-EOQ
    select
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group,
        'Region', s.region
      ) as properties
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(s.source_resource_id) = lower(d.id)
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "compute_snapshot_to_compute_disk" {
  title = "disk"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_snapshot as s
      left join azure_compute_disk as d on s.source_resource_id = d.id
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "azure_compute_disk_to_compute_snapshot_node" {
  category = category.compute_snapshot

  sql = <<-EOQ
    select
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'OS Type', s.os_type,
        'SKU Nam', s.sku_name,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group,
        'Region', s.region
      ) as properties
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(s.id) = lower(d.creation_data_source_resource_id)
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "compute_disk_to_compute_snapshot" {
  title = "snapshot source for disk"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(s.id) = lower(d.creation_data_source_resource_id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "compute_disk_to_compute_disk" {
  category = category.compute_disk

  sql = <<-EOQ
    select
      lower(d2.id) as id,
      d2.title as title,
      jsonb_build_object(
        'Name', d2.name,
        'ID', d2.id,
        'OS Type', d2.os_type,
        'SKU Nam', d2.sku_name,
        'Subscription ID', d2.subscription_id,
        'Resource Group', d2.resource_group,
        'Region', d2.region
      ) as properties
    from
      azure_compute_disk as d1
      left join azure_compute_disk d2 on d1.creation_data_source_resource_id = d2.id
    where
      lower(d1.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

edge "compute_disk_to_compute_disk" {
  title = "disk source for disk"

  sql = <<-EOQ
    select
      lower(d2.id) as from_id,
      lower(d1.id) as to_id
    from
      azure_compute_disk as d1
      left join azure_compute_disk d2 on d1.creation_data_source_resource_id = d2.id
    where
      lower(d1.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "azure_compute_disk_to_storage_storage_account_node" {
  category = category.storage_storage_account

  sql = <<-EOQ
   select
      a.id as id,
      a.title as title,
      jsonb_build_object(
        'Name', a.name,
        'ID', a.id,
        'Type', a.type,
        'Region', a.region,
        'Resource Group', a.resource_group,
        'Subscription ID', a.subscription_id
      ) as properties
    from
      azure_compute_disk as d
      left join azure_storage_account as a on lower(a.id) = lower(d.creation_data_storage_account_id)
    where
      d.id = $1;
  EOQ

  param "id" {}
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

query "compute_disk_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      type as "Type",
      provisioning_state as "Provisioning State",
      time_created as "Time Created",
      disk_access_id as "Disk Access ID",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_compute_disk
    where
      lower(id) = $1
  EOQ

  param "id" {}
}

query "compute_disk_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_compute_disk
    where
      lower(id) = $1
    order by
      tags ->> 'Key';
    EOQ

  param "id" {}
}

query "compute_disk_associated_virtual_machine_details" {
  sql = <<-EOQ
    (
      select
        name as "Name",
        type as "Type",
        id as "ID"
      from
        azure_compute_virtual_machine,
        jsonb_array_elements(data_disks)  as data_disk
      where
        lower(data_disk -> 'managedDisk' ->> 'id' ) = $1
    )
    union
    (
      select
        name as "Name",
        type as "Type",
        id as "ID"
      from
        azure_compute_virtual_machine
      where
        lower(managed_disk_id) = $1
    )
EOQ

  param "id" {}
}

query "compute_disk_encryption_set_details" {
  sql = <<-EOQ
    select
      e.name as "Name",
      e.encryption_type as "Encryption Type",
      v.name as "Key Vault Name",
      v.id as "Key Vault ID",
      k.id as "Key ID",
      k.name as "Key Name",
      e.id as "ID"
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
      left join azure_key_vault as v on v.id = e.active_key_source_vault_id
      left join azure_key_vault_key as k on k.key_uri_with_version = e.active_key_url
    where
      lower(d.id) = $1;
  EOQ

  param "id" {}
}
