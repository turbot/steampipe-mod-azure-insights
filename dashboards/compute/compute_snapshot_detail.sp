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
      query = query.azure_compute_snapshot_incremental
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_snapshot_create_option
      args = {
        id = self.input.id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_snapshot_network_access_policy
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
        node.azure_compute_snapshot_node,
        node.azure_compute_snapshot_to_compute_disk_node,
        node.azure_compute_snapshot_from_compute_snapshot_node,
        node.azure_compute_snapshot_to_compute_disk_encryption_set_node,
        node.azure_compute_snapshot_compute_disk_encryption_set_to_key_vault_node,
        node.azure_compute_snapshot_compute_disk_encryption_set_key_vault_to_key_node,
        node.azure_compute_snapshot_from_compute_disk_node

      ]

      edges = [
        edge.azure_compute_snapshot_to_compute_disk_edge,
        edge.azure_compute_snapshot_to_compute_snapshot_edge,
        edge.azure_compute_snapshot_to_compute_disk_encryption_set_edge,
        edge.azure_compute_snapshot_compute_disk_encryption_set_to_key_vault_edge,
        edge.azure_compute_snapshot_compute_disk_encryption_set_key_vault_to_key_edge,
        edge.azure_compute_snapshot_from_compute_snapshot_edge,
        edge.azure_compute_snapshot_from_compute_disk_edge
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
        title = "Disk Encryption Set"
        query = query.azure_compute_disk_encryption_details
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
          href = "${dashboard.azure_key_vault_detail.url_path}?input.key_vault_id={{.'Key Vault ID' | @uri}}"
        }

        column "Key Name" {
          href = "${dashboard.azure_key_vault_key_detail.url_path}?input.key_vault_key_id={{.'Key ID' | @uri}}"
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

query "azure_compute_snapshot_incremental" {
  sql = <<-EOQ
    select
      'Incremental' as label,
      case when incremental then 'Enabled' else 'Disabled' end as value
    from
      azure_compute_snapshot
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_snapshot_create_option" {
  sql = <<-EOQ
    select
      'Create Option' as label,
      create_option as value
    from
      azure_compute_snapshot
    where
      id = $1;
  EOQ

  param "id" {}
}


query "azure_compute_snapshot_network_access_policy" {
  sql = <<-EOQ
    select
      'Network Access Policy' as label,
      network_access_policy as value,
      case when network_access_policy = 'AllowAll' then 'alert' else 'ok' end as type
    from
      azure_compute_snapshot
    where
      id = $1;
  EOQ

  param "id" {}

}

category "azure_compute_snapshot_no_link" {
  icon  = "viewfinder-circle"
  color = "green"
}

node "azure_compute_snapshot_node" {
  category = category.azure_compute_snapshot_no_link

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

edge "azure_compute_snapshot_from_compute_snapshot_edge" {
  title = "snapshot"

  sql = <<-EOQ
    select
      s.id as to_id,
      d.id as from_id
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on lower(d.id) = lower(s.source_resource_id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_from_compute_snapshot_node" {
  category = category.azure_compute_snapshot

  sql = <<-EOQ
    with self as (
      select 
        id, 
        source_resource_id 
      from 
        azure_compute_snapshot 
      where 
        id = $1)
    select
      acs.id as id,
      acs.title as title,
      jsonb_build_object(
        'Name', acs.name,
        'ID', acs.id,
        'Subscription ID', acs.subscription_id,
        'Resource Group', acs.resource_group,
        'Region', acs.region
      ) as properties
    from
      azure_compute_snapshot as acs,
      self
    where
      acs.id = self.source_resource_id
      or
      acs.source_resource_id = self.id;
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_to_compute_snapshot_edge" {
  title = "snapshot"

  sql = <<-EOQ
    select
      s.id as to_id,
      s.source_resource_id as from_id
    from
      azure_compute_snapshot as s
    where
      s.source_resource_id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_to_compute_disk_encryption_set_node" {
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

edge "azure_compute_snapshot_to_compute_disk_encryption_set_edge" {
  title = "disk encryption set"

  sql = <<-EOQ
    select
      s.id as from_id,
      e.id as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on lower(s.disk_encryption_set_id) = lower(e.id)
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_compute_disk_encryption_set_to_key_vault_node" {
  category = category.azure_key_vault

  sql = <<-EOQ
    select
      k.id as id,
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
      left join azure_compute_snapshot as s on s.disk_encryption_set_id = e.id
      left join azure_key_vault as k on e.active_key_source_vault_id = k.id
    where
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_compute_disk_encryption_set_to_key_vault_edge" {
  title = "key vault"

  sql = <<-EOQ
    select
      e.id as from_id,
      k.id as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on s.disk_encryption_set_id = e.id
      left join azure_key_vault as k on e.active_key_source_vault_id = k.id
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_compute_disk_encryption_set_key_vault_to_key_node" {
  category = category.azure_key_vault_key

  sql = <<-EOQ
    select
      k.id as id,
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
      left join azure_compute_snapshot as s on s.disk_encryption_set_id = e.id
      left join azure_key_vault_key as k on e.active_key_url = k.key_uri_with_version
    where
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_compute_disk_encryption_set_key_vault_to_key_edge" {
  title = "key"

  sql = <<-EOQ
    select
      e.active_key_source_vault_id as from_id,
      k.id as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_snapshot as s on s.disk_encryption_set_id = e.id
      left join azure_key_vault_key as k on e.active_key_url = k.key_uri_with_version
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_snapshot_from_compute_disk_node" {
  category = category.azure_compute_disk

  sql = <<-EOQ
    select
      d.id as id,
      d.title as title,
      d.creation_data_source_resource_id,
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
      lower(s.id) = lower($1);
  EOQ

  param "id" {}
}

edge "azure_compute_snapshot_from_compute_disk_edge" {
  title = "snapshot"

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
      d.name as "Name",
      d.type as  "Type",
      d.id as "ID"
    from
      azure_compute_snapshot as s
      left join azure_compute_disk as d on lower(d.id) = lower(s.source_resource_id)
    where
      lower(s.id) = lower('/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/DATABASE-RG/providers/Microsoft.Compute/snapshots/tets56')

    -- Compute Snapshot
    union
    select
      d.name as "Name",
      d.type as  "Type",
      d.id as "ID"
    from
      azure_compute_snapshot as d
      left join azure_compute_snapshot as s on d.id = s.source_resource_id
    where
      lower(s.id) = lower('/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/DATABASE-RG/providers/Microsoft.Compute/snapshots/tets56')
  EOQ

  param "id" {}
}

query "azure_compute_disk_encryption_details" {
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
      left join azure_compute_snapshot as s on s.disk_encryption_set_id = e.id
      left join azure_key_vault as v on v.id = e.active_key_source_vault_id
      left join azure_key_vault_key as k on k.key_uri_with_version = e.active_key_url
    where
      s.id = $1;
  EOQ

  param "id" {}
}
