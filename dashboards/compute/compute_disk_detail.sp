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
      args  = [self.input.disk_id.value]
    }

    card {
      width = 2
      query = query.compute_disk_os_type
      args  = [self.input.disk_id.value]
    }

    card {
      width = 2
      query = query.compute_disk_sku_name
      args  = [self.input.disk_id.value]
    }

    card {
      width = 2
      query = query.compute_disk_status
      args  = [self.input.disk_id.value]
    }

    card {
      width = 2
      query = query.compute_disk_network_access_policy
      args  = [self.input.disk_id.value]
    }

  }

  with "compute_disk_accesses_for_compute_disk" {
    query = query.compute_disk_accesses_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  with "compute_disk_encryption_sets_for_compute_disk" {
    query = query.compute_disk_encryption_sets_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  with "compute_snapshots_for_compute_disk" {
    query = query.compute_snapshots_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  with "source_compute_disks_for_compute_disk" {
    query = query.source_compute_disks_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  with "compute_virtual_machines_for_compute_disk" {
    query = query.compute_virtual_machines_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  with "key_vault_keys_for_compute_disk" {
    query = query.key_vault_keys_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  with "key_vault_vaults_for_compute_disk" {
    query = query.key_vault_vaults_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  with "storage_storage_accounts_for_compute_disk" {
    query = query.storage_storage_accounts_for_compute_disk
    args  = [self.input.disk_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.compute_disk
        args = {
          compute_disk_ids = [self.input.disk_id.value]
        }
      }

      node {
        base = node.compute_disk
        args = {
          compute_disk_ids = with.source_compute_disks_for_compute_disk.rows[*].compute_disk_id
        }
      }

      node {
        base = node.compute_disk_access
        args = {
          compute_disk_access_ids = with.compute_disk_accesses_for_compute_disk.rows[*].disk_access_id
        }
      }

      node {
        base = node.compute_disk_encryption_set
        args = {
          compute_disk_encryption_set_ids = with.compute_disk_encryption_sets_for_compute_disk.rows[*].encryption_set_id
        }
      }

      node {
        base = node.compute_snapshot
        args = {
          compute_snapshot_ids = with.compute_snapshots_for_compute_disk.rows[*].compute_snapshot_id
        }
      }

      node {
        base = node.compute_virtual_machine
        args = {
          compute_virtual_machine_ids = with.compute_virtual_machines_for_compute_disk.rows[*].virtual_machine_id
        }
      }

      node {
        base = node.key_vault_key
        args = {
          key_vault_key_ids = with.key_vault_keys_for_compute_disk.rows[*].key_vault_key_id
        }
      }

      node {
        base = node.key_vault_vault
        args = {
          key_vault_vault_ids = with.key_vault_vaults_for_compute_disk.rows[*].key_vault_id
        }
      }

      node {
        base = node.storage_storage_account
        args = {
          storage_account_ids = with.storage_storage_accounts_for_compute_disk.rows[*].storage_account_id
        }
      }

      edge {
        base = edge.compute_disk_encryption_set_to_key_vault_vault
        args = {
          compute_disk_encryption_set_ids = with.compute_disk_encryption_sets_for_compute_disk.rows[*].encryption_set_id
        }
      }

      edge {
        base = edge.compute_disk_to_compute_disk
        args = {
          compute_disk_ids = [self.input.disk_id.value]
        }
      }

      edge {
        base = edge.compute_disk_to_compute_disk_access
        args = {
          compute_disk_ids = [self.input.disk_id.value]
        }
      }

      edge {
        base = edge.compute_disk_to_compute_disk_encryption_set
        args = {
          compute_disk_ids = [self.input.disk_id.value]
        }
      }

      edge {
        base = edge.compute_snapshot_to_compute_disk
        args = {
          compute_disk_ids = [self.input.disk_id.value]
        }
      }

      edge {
        base = edge.compute_disk_to_key_vault_key
        args = {
          compute_disk_ids = [self.input.disk_id.value]
        }
      }

      edge {
        base = edge.storage_storage_account_to_compute_disk
        args = {
          storage_account_ids = with.storage_storage_accounts_for_compute_disk.rows[*].storage_account_id
        }
      }

      edge {
        base = edge.compute_snapshots_to_compute_disk
        args = {
          compute_snapshot_ids = with.compute_snapshots_for_compute_disk.rows[*].compute_snapshot_id
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_compute_disk
        args = {
          compute_virtual_machine_ids = with.compute_virtual_machines_for_compute_disk.rows[*].virtual_machine_id
        }
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
        args  = [self.input.disk_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_disk_tags
        args  = [self.input.disk_id.value]
      }
    }

    container {

      width = 6

      table {
        title = "Attached To"
        query = query.compute_disk_associated_virtual_machine_details
        args  = [self.input.disk_id.value]

        column "Name" {
          href = "${dashboard.compute_virtual_machine_detail.url_path}?input.vm_id={{.ID | @uri}}"
        }
      }

      table {
        title = "Disk Encryption Set"
        query = query.compute_disk_encryption_set_details
        args  = [self.input.disk_id.value]

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

# Card Queries

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
}

# With Queries

query "compute_disk_accesses_for_compute_disk" {
  sql = <<-EOQ
    select
      lower(a.id) as disk_access_id
    from
      azure_compute_disk_access as a
      left join azure_compute_disk as d on lower(d.disk_access_id) = lower(a.id)
    where
      lower(d.id) = $1;
  EOQ
}

query "compute_disk_encryption_sets_for_compute_disk" {
  sql = <<-EOQ
    select
      lower(e.id) as encryption_set_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
    where
      lower(d.id) = $1;
  EOQ
}

query "compute_snapshots_for_compute_disk" {
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
}

query "source_compute_disks_for_compute_disk" {
  sql = <<-EOQ
    select
      lower(d2.id) as compute_disk_id
    from
      azure_compute_disk as d1
      left join azure_compute_disk d2 on d1.creation_data_source_resource_id = d2.id
    where
      lower(d1.id) = $1
      and lower(d2.id) is not null;
  EOQ
}

query "compute_virtual_machines_for_compute_disk" {
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
}

query "key_vault_keys_for_compute_disk" {
  sql = <<-EOQ
    select
      lower(k.id) as key_vault_key_id,
      lower(v.key_uri_with_version) as key_uri_with_version
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on lower(d.encryption_disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault_key_version as v on lower(e.active_key_url) = lower(v.key_uri_with_version)
      left join azure_key_vault_key as k on lower(k.key_uri) = lower(v.key_uri)
    where
      lower(d.id) = $1;
  EOQ
}

query "key_vault_vaults_for_compute_disk" {
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
}

query "storage_storage_accounts_for_compute_disk" {
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
}

# Table Queries

query "compute_disk_overview" {
  sql = <<-EOQ
    select
      name as "Name",
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
}

query "compute_disk_associated_virtual_machine_details" {
  sql = <<-EOQ
    (
      select
        name as "Name",
        type as "Type",
        lower(id) as "ID"
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
        lower(id) as "ID"
      from
        azure_compute_virtual_machine
      where
        lower(managed_disk_id) = $1
    )
  EOQ
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
      left join azure_key_vault_key_version as k on k.key_uri_with_version = e.active_key_url
    where
      lower(d.id) = $1;
  EOQ
}
