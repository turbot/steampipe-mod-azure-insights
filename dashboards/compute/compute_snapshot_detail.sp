dashboard "azure_compute_snapshot_detail" {

  title         = "Azure Compute Snapshot Detail"
  documentation = file("./dashboards/compute/docs/compute_snapshot_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "id" {
    title = "Select a snapshot:"
    query = query.azure_compute_snapshot_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_compute_snapshot_sku_name
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_snapshot_sku_tier
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_snapshot_incremental
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

      nodes = [
        node.azure_compute_snapshot,
        node.azure_compute_snapshot_to_compute_disk_node,
        node.azure_compute_snapshot_to_compute_snapshot_node,
        node.azure_compute_snapshot_from_compute_disk_encryption_set_node,
        node.azure_compute_snapshot_from_manage_disk_node

      ]

      edges = [
        edge.azure_compute_snapshot_to_compute_disk_edge,
        edge.azure_compute_snapshot_to_compute_snapshot_edge,
        edge.azure_compute_snapshot_from_compute_disk_encryption_set_edge,
        edge.azure_compute_snapshot_from_manage_disk_edge
      ]

      args = {
        id = self.input.id.value
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
        query = query.azure_compute_snapshot_overview
        args = {
          id = self.input.id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_compute_snapshot_tags
        args = {
          id = self.input.id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Source"
        query = query.azure_compute_snapshot_source_details
        args = {
          id = self.input.id.value
        }

      }

      table {
      title = "Disk Encryption"
      query = query.azure_compute_disk_encryption_details
      args = {
        id = self.input.id.value
      }
    }

    }

  }
}

query "azure_compute_snapshot_input" {
  sql = <<-EOQ
    select
      c.title as label,
      c.id as value,
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

query "azure_compute_snapshot_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_compute_snapshot
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_snapshot_sku_tier" {
  sql = <<-EOQ
    select
      'SKU Tier' as label,
      sku_tier as value
    from
      azure_compute_snapshot
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_snapshot_incremental" {
  sql = <<-EOQ
    select
      'Incremental' as label,
      case when incremental then 'Enabled' else 'Disabled' end as value,
      case when incremental then 'ok' else 'alert' end as type
    from
      azure_compute_snapshot
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot" {
  category = category.azure_compute_snapshot

  sql = <<-EOQ
    select
      id as id,
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
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_to_compute_disk_node" {
  category = category.azure_compute_disk

  sql = <<-EOQ
    select
      d.id as id,
      d.title as title,
      jsonb_build_object(
        'Name', d.name,
        'ID', d.id,
        'Subscription ID', d.subscription_id,
        'Resource Group', d.resource_group,
        'Region', d.region
      ) as properties
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_to_compute_disk_edge" {
  title = "source disk"

  sql = <<-EOQ
    select
      s.id as from_id,
      d.id as to_id
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_to_compute_snapshot_node" {
  category = category.azure_compute_snapshot

  sql = <<-EOQ
    select
      d.id as id,
      d.title as title,
      jsonb_build_object(
        'Name', d.name,
        'ID', d.id,
        'Subscription ID', d.subscription_id,
        'Resource Group', d.resource_group,
        'Region', d.region
      ) as properties
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_to_compute_snapshot_edge" {
  title = "source snapshot"

  sql = <<-EOQ
    select
      s.id as from_id,
      d.id as to_id
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_from_compute_disk_encryption_set_node" {
  category = category.azure_compute_disk_encryption_set

  sql = <<-EOQ
    select
      e.id as id,
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
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_from_compute_disk_encryption_set_edge" {
  title = "disk encryption set"

  sql = <<-EOQ
    select
      e.id as from_id,
      s.id as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_from_manage_disk_node" {
  category = category.azure_compute_disk

  sql = <<-EOQ
    select
      d.id as id,
      d.title as title,
      jsonb_build_object(
        'Name', d.name,
        'ID', d.id,
        'Subscription ID', d.subscription_id,
        'Resource Group', d.resource_group,
        'Region', d.region
      ) as properties
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(d.creation_data_source_resource_id) = lower(s.id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_from_manage_disk_edge" {
  title = "managed disk"

  sql = <<-EOQ
    select
      d.id as from_id,
      s.id as to_id
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on lower(d.creation_data_source_resource_id) = lower(s.id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_snapshot_overview" {
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
      id = $1
  EOQ

  param "id" {}
}

query "azure_compute_snapshot_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_compute_snapshot
    where
      id = $1
    order by
      tags ->> 'Key';
    EOQ

  param "id" {}
}

query "azure_compute_snapshot_source_details" {
  sql = <<-EOQ

    -- Compute Disk
    select
      d.title as "Title",
      d.type as  "Type",
      d.id as "ID"
    from
      azure_compute_disk as d
      left join azure_compute_snapshot as s on d.id = s.source_resource_id
    where
      s.id = $1

    -- Compute Snapshot
    union all
    select
      d.title as "Title",
      d.type as  "Type",
      d.id as "ID"
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on d.id = s.source_resource_id
    where
      s.id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_disk_encryption_details" {
  sql = <<-EOQ
    select
      e.name as "Name",
      e.type as "Type",
      e.active_key_source_vault_id as "Key Vault ID",
      e.active_key_url as "Key URI",
      e.id as "ID"
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on s.disk_encryption_set_id = e.id
    where
      s.id = $1;
  EOQ

  param "id" {}
}
