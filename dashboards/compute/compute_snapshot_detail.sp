dashboard "compute_snapshot_detail" {

  title         = "Azure Compute Snapshot Detail"
  documentation = file("./dashboards/compute/docs/compute_snapshot_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "id" {
    title = "Select a snapshot:"
    query = query.compute_snapshot_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.compute_snapshot_sku_name
      args  = [self.input.id.value]
    }

    card {
      width = 3
      query = query.compute_snapshot_incremental
      args  = [self.input.id.value]
    }

    card {
      width = 3
      query = query.compute_snapshot_create_option
      args  = [self.input.id.value]
    }

    card {
      width = 3
      query = query.compute_snapshot_network_access_policy
      args  = [self.input.id.value]
    }

  }

  with "target_compute_disks_for_compute_snapshot" {
    query = query.target_compute_disks_for_compute_snapshot
    args  = [self.input.id.value]
  }

  with "compute_disk_accesses_for_compute_snapshot" {
    query = query.compute_disk_accesses_for_compute_snapshot
    args  = [self.input.id.value]
  }

  with "compute_disk_encryption_sets_for_compute_snapshot" {
    query = query.compute_disk_encryption_sets_for_compute_snapshot
    args  = [self.input.id.value]
  }

  with "source_compute_snapshots_for_compute_snapshot" {
    query = query.source_compute_snapshots_for_compute_snapshot
    args  = [self.input.id.value]
  }

  with "source_compute_disks_for_compute_snapshot" {
    query = query.source_compute_disks_for_compute_snapshot
    args  = [self.input.id.value]
  }

  with "key_vault_keys_for_compute_snapshot" {
    query = query.key_vault_keys_for_compute_snapshot
    args  = [self.input.id.value]
  }

  with "key_vault_vaults_for_compute_snapshot" {
    query = query.key_vault_vaults_for_compute_snapshot
    args  = [self.input.id.value]
  }

  with "target_compute_snapshots_for_compute_snapshot" {
    query = query.target_compute_snapshots_for_compute_snapshot
    args  = [self.input.id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.compute_disk
        args = {
          compute_disk_ids = with.target_compute_disks_for_compute_snapshot.rows[*].disk_id
        }
      }

      node {
        base = node.compute_disk
        args = {
          compute_disk_ids = with.source_compute_disks_for_compute_snapshot.rows[*].disk_id
        }
      }

      node {
        base = node.compute_disk_access
        args = {
          compute_disk_access_ids = with.compute_disk_accesses_for_compute_snapshot.rows[*].disk_access_id
        }
      }

      node {
        base = node.compute_disk_encryption_set
        args = {
          compute_disk_encryption_set_ids = with.compute_disk_encryption_sets_for_compute_snapshot.rows[*].encryption_set_id
        }
      }

      node {
        base = node.compute_snapshot
        args = {
          compute_snapshot_ids = [self.input.id.value]
        }
      }

      node {
        base = node.compute_snapshot
        args = {
          compute_snapshot_ids = with.source_compute_snapshots_for_compute_snapshot.rows[*].snapshot_id
        }
      }

      node {
        base = node.compute_snapshot
        args = {
          compute_snapshot_ids = with.target_compute_snapshots_for_compute_snapshot.rows[*].snapshot_id
        }
      }

      node {
        base = node.key_vault_key
        args = {
          key_vault_key_ids = with.key_vault_keys_for_compute_snapshot.rows[*].key_vault_key_id
        }
      }

      node {
        base = node.key_vault_vault
        args = {
          key_vault_vault_ids = with.key_vault_vaults_for_compute_snapshot.rows[*].key_vault_id
        }
      }

      edge {
        base = edge.compute_disks_to_compute_snapshot
        args = {
          compute_disk_ids = with.source_compute_disks_for_compute_snapshot.rows[*].disk_id
        }
      }

      edge {
        base = edge.compute_snapshot_to_compute_disks
        args = {
          compute_snapshot_ids = [self.input.id.value]
        }
      }

      edge {
        base = edge.compute_snapshot_to_compute_disk_access
        args = {
          compute_snapshot_ids = [self.input.id.value]
        }
      }

      edge {
        base = edge.compute_snapshot_to_compute_disk_encryption_set
        args = {
          compute_snapshot_ids = [self.input.id.value]
        }
      }

      edge {
        base = edge.compute_snapshot_to_compute_snapshot
        args = {
          compute_snapshot_ids = [self.input.id.value]
        }
      }

      edge {
        base = edge.compute_snapshot_to_compute_snapshot
        args = {
          compute_snapshot_ids = with.source_compute_snapshots_for_compute_snapshot.rows[*].snapshot_id
        }
      }

      edge {
        base = edge.compute_snapshot_to_key_vault_key
        args = {
          compute_snapshot_ids = [self.input.id.value]
        }
      }

      edge {
        base = edge.compute_disk_encryption_set_to_key_vault_vault
        args = {
          compute_disk_encryption_set_ids = with.compute_disk_encryption_sets_for_compute_snapshot.rows[*].encryption_set_id
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
        query = query.compute_snapshot_overview
        args  = [self.input.id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_snapshot_tags
        args  = [self.input.id.value]
      }
    }

    container {

      width = 6

      table {
        title = "Source"
        query = query.compute_snapshot_source_details
        args  = [self.input.id.value]

        column "link" {
          display = "none"
        }
        // Not able to link source snapshots as it throws cyclic dependency
        column "Name" {
          href = "{{ .link }}"
        }
      }

      table {
        title = "Disk Encryption Set"
        query = query.compute_disk_encryption_details
        args  = [self.input.id.value]

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

query "compute_snapshot_input" {
  sql = <<-EOQ
    select
      c.title as label,
      lower(c.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', c.resource_group,
        'region', c.region
      ) as tags
    from
      azure_compute_snapshot as c,
      azure_subscription as s
    where
      c.subscription_id = s.subscription_id
    order by
      c.title;
  EOQ
}

# Card Queries

query "compute_snapshot_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_compute_snapshot
    where
      lower(id) = $1;
  EOQ
}

query "compute_snapshot_incremental" {
  sql = <<-EOQ
    select
      'Incremental' as label,
      case when incremental then 'Enabled' else 'Disabled' end as value
    from
      azure_compute_snapshot
    where
      lower(id) = $1;
  EOQ
}

query "compute_snapshot_create_option" {
  sql = <<-EOQ
    select
      'Create Option' as label,
      create_option as value
    from
      azure_compute_snapshot
    where
      lower(id) = $1;
  EOQ
}

query "compute_snapshot_network_access_policy" {
  sql = <<-EOQ
    select
      'Network Access Policy' as label,
      network_access_policy as value,
      case when network_access_policy = 'AllowAll' then 'alert' else 'ok' end as type
    from
      azure_compute_snapshot
    where
      lower(id) = $1;
  EOQ

}

# With Queries

query "target_compute_disks_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(d.id) as disk_id
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(d.creation_data_source_resource_id) = lower(s.id)
    where
      lower(s.id) = $1;
  EOQ
}

query "compute_disk_accesses_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(a.id) as disk_access_id
    from
      azure_compute_disk_access as a
      left join azure_compute_snapshot as s on lower(s.disk_access_id) = lower(a.id)
    where
      lower(s.id) = $1;
  EOQ
}

query "compute_disk_encryption_sets_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(e.id) as encryption_set_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
    where
      lower(s.id) = $1;
  EOQ
}

query "key_vault_keys_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(k.id) as key_vault_key_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault_key_version as v on lower(e.active_key_url) = lower(v.key_uri_with_version)
      left join azure_key_vault_key as k on lower(k.key_uri) = lower(v.key_uri)
    where
      lower(s.id) = $1;
  EOQ
}

query "key_vault_vaults_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(k.id) as key_vault_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault as k on lower(e.active_key_source_vault_id) = lower(k.id)
    where
      lower(s.id) = $1;
  EOQ
}

query "source_compute_snapshots_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(s.id) as snapshot_id
    from
      azure_compute_snapshot as s,
      azure_compute_snapshot as self
    where
      lower(self.source_resource_id) = lower(s.id)
    and
      lower(self.id) = $1;
  EOQ
}

query "source_compute_disks_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(d.id) as disk_id
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      lower(s.id) = $1;
  EOQ
}

query "target_compute_snapshots_for_compute_snapshot" {
  sql = <<-EOQ
    select
      lower(s.id) as snapshot_id
    from
      azure_compute_snapshot as s
    where
      lower(s.source_resource_id) = $1;
  EOQ
}

# Table Queries

query "compute_snapshot_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      type as "Type",
      unique_id as "Unique ID",
      disk_size_gb as "Disk Size GB",
      provisioning_state as "Provisioning State",
      os_type as "OS Type",
      time_created as "Time Created",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_compute_snapshot
    where
      lower(id) = $1
  EOQ
}

query "compute_snapshot_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_compute_snapshot
    where
      lower(id) = $1
    order by
      tags ->> 'Key';
  EOQ
}

query "compute_snapshot_source_details" {
  sql = <<-EOQ

    -- Compute Disk
    select
      d.name as "Name",
      d.type as  "Type",
      lower(d.id) as "ID",
      '${dashboard.compute_disk_detail.url_path}?input.disk_id=' || lower(d.id) as link
    from
      azure_compute_snapshot as s
      left join azure_compute_disk as d on lower(d.id) = lower(s.source_resource_id)
    where
      d.id is not null
      and lower(s.id) = $1

    -- Compute Snapshot
    union
    select
      d.name as "Name",
      d.type as  "Type",
      lower(d.id) as "ID",
      null  as link
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      d.id is not null
      and lower(s.id) = $1
  EOQ
}

query "compute_disk_encryption_details" {
  sql = <<-EOQ
    select
      e.name as "Name",
      e.encryption_type as "Encryption Type",
      v.name as "Key Vault Name",
      lower(v.id) as "Key Vault ID",
      lower(k.key_id) as "Key ID",
      k.name as "Key Name",
      e.id as "ID"
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault as v on lower(v.id) = lower(e.active_key_source_vault_id)
      left join azure_key_vault_key_version as k on lower(k.key_uri_with_version) = lower(e.active_key_url)
    where
      lower(s.id) = $1;
  EOQ
}
