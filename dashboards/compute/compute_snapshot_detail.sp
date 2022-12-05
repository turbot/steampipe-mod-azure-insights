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
      width = 2
      query = query.compute_snapshot_sku_name
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.compute_snapshot_incremental
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.compute_snapshot_create_option
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.compute_snapshot_network_access_policy
      args = {
        id = self.input.id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "compute_disks" {
        sql = <<-EOQ
          select
            lower(d.id) as disk_id
          from
            azure_compute_disk as d
            left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
          where
            lower(s.id) = $1
          union
          select
            lower(d.id) as disk_id
          from
            azure_compute_disk as d
            left join azure_compute_snapshot as s on lower(d.creation_data_source_resource_id) = lower(s.id)
          where
            lower(s.id) = $1;
          EOQ

        args = [self.input.id.value]
      }

      with "key_vault" {
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

        args = [self.input.id.value]
      }

      with "key_vault_keys" {
        sql = <<-EOQ
          select
            lower(k.id) as key_id
          from
            azure_compute_disk_encryption_set as e
            left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
            left join azure_key_vault_key_version as v on lower(e.active_key_url) = lower(v.key_uri_with_version)
            left join azure_key_vault_key as k on lower(k.key_uri) = lower(v.key_uri)
          where
            lower(s.id) = $1;
          EOQ

        args = [self.input.id.value]
      }

      nodes = [
        node.compute_snapshot,
        node.compute_disk,
        node.compute_snapshot_to_compute_disk_encryption_set,
        node.key_vault,
        node.key_vault_key,
        node.compute_snapshot_compute_disk_access,

        node.compute_snapshot_to_compute_snapshot
      ]

      edges = [
        edge.compute_snapshot_to_compute_disk,
        edge.compute_snapshot_to_compute_snapshot,
        edge.compute_snapshot_to_compute_disk_encryption_set,
        edge.compute_snapshot_to_key_vault,
        edge.compute_snapshot_to_key_vault_key,
        edge.compute_snapshot_from_compute_snapshot,
        edge.compute_disk_to_compute_snapshot,
        edge.compute_snapshot_to_compute_disk_access
      ]

      args = {
        compute_disk_ids     = with.compute_disks.rows[*].disk_id
        compute_snapshot_ids = [self.input.id.value]
        key_vault_ids        = with.key_vault.rows[*].key_vault_id
        key_vault_key_ids    = with.key_vault_keys.rows[*].key_id
        id                   = self.input.id.value
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
        args = {
          id = self.input.id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_snapshot_tags
        args = {
          id = self.input.id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Source"
        query = query.compute_snapshot_source_details
        args = {
          id = self.input.id.value
        }

      }

      table {
        title = "Disk Encryption Set"
        query = query.compute_disk_encryption_details
        args = {
          id = self.input.id.value
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}

}

node "compute_snapshot" {
  category = category.azure_compute_snapshot

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
      azure_compute_snapshot
    where
      lower(id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

edge "compute_snapshot_from_compute_snapshot" {
  title = "duplicate of"

  sql = <<-EOQ
    select
      lower(s.id) as to_id,
      lower(d.id) as from_id
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

node "compute_snapshot_to_compute_snapshot" {
  category = category.azure_compute_snapshot

  sql = <<-EOQ
    with self as (
      select
        id,
        source_resource_id
      from
        azure_compute_snapshot
      where
        lower(id) = any($1)
    )
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
      azure_compute_snapshot as s,
      self
    where
      lower(s.id) = lower(self.source_resource_id)
    union
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
      azure_compute_snapshot as s,
      self
    where
      lower(s.source_resource_id) = lower(self.id);
  EOQ

  param "compute_snapshot_ids" {}
}

edge "compute_snapshot_to_compute_snapshot" {
  title = "duplicate of"

  sql = <<-EOQ
    select
      lower(s.source_resource_id) as to_id,
      lower(s.id) as from_id
    from
      azure_compute_snapshot as s
    where
      lower(s.source_resource_id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

node "compute_snapshot_to_compute_disk_encryption_set" {
  category = category.azure_compute_disk_encryption_set

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
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

edge "compute_snapshot_to_compute_disk_encryption_set" {
  title = "disk encryption set"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(e.id) as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

edge "compute_snapshot_to_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(e.id) as from_id,
      lower(k.id) as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault as k on lower(e.active_key_source_vault_id) = lower(k.id)
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

edge "compute_snapshot_to_key_vault_key" {
  title = "key"

  sql = <<-EOQ
    select
      lower(e.active_key_source_vault_id) as from_id,
      lower(k.id) as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault_key_version as v on lower(e.active_key_url) = lower(k.key_uri_with_version)
      left join azure_key_vault_key as k on lower(k.key_uri) = lower(v.key_uri)
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

node "compute_snapshot_compute_disk_access" {
  category = category.azure_compute_disk_access

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
      left join azure_compute_snapshot as s on lower(s.disk_access_id) = lower(a.id)
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

edge "compute_snapshot_to_compute_disk_access" {
  title = "disk access"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(a.id) as to_id
    from
      azure_compute_disk_access as a
      left join azure_compute_snapshot as s on lower(s.disk_access_id) = lower(a.id)
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

query "compute_snapshot_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      type as "Type",
      provisioning_state as "Provisioning State",
      os_type as "OS Type",
      time_created as "Time Created",
      disk_access_id as "Disk Access ID",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_compute_snapshot
    where
      lower(id) = $1
  EOQ

  param "id" {}
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

  param "id" {}
}

query "compute_snapshot_source_details" {
  sql = <<-EOQ

    -- Compute Disk
    select
      d.name as "Name",
      d.type as  "Type",
      d.id as "ID"
    from
      azure_compute_snapshot as s
      left join azure_compute_disk as d on lower(d.id) = lower(s.source_resource_id)
    where
      lower(s.id) = $1

    -- Compute Snapshot
    union
    select
      d.name as "Name",
      d.type as  "Type",
      d.id as "ID"
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      lower(s.id) = $1
  EOQ

  param "id" {}
}

query "compute_disk_encryption_details" {
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
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
      left join azure_key_vault as v on lower(v.id) = lower(e.active_key_source_vault_id)
      left join azure_key_vault_key as k on lower(k.key_uri_with_version) = lower(e.active_key_url)
    where
      lower(s.id) = $1;
  EOQ

  param "id" {}
}
