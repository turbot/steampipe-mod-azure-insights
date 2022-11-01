dashboard "azure_compute_disk_detail" {

  title         = "Azure Compute Disk Detail"
  documentation = file("./dashboards/compute/docs/compute_disk_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "disk_id" {
    title = "Select a disk:"
    query = query.azure_compute_disk_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_compute_disk_status
      args = {
        id = self.input.disk_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_disk_os_type
      args = {
        id = self.input.disk_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_disk_sku_name
      args = {
        id = self.input.disk_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_disk_encryption_status
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

      nodes = [
        node.azure_compute_disk_node,
        node.azure_compute_disk_from_compute_virtual_machine_node,
        node.azure_compute_disk_to_compute_disk_encryption_set_node,
        node.azure_compute_disk_compute_disk_encryption_set_to_key_vault_node,
        node.azure_compute_disk_compute_disk_encryption_set_key_vault_to_key_node,
        node.azure_compute_disk_to_compute_snapshot_node

      ]

      edges = [
        edge.azure_compute_disk_from_compute_virtual_machine_edge,
        edge.azure_compute_disk_to_compute_disk_encryption_set_edge,
        edge.azure_compute_disk_compute_disk_encryption_set_to_key_vault_edge,
        edge.azure_compute_disk_compute_disk_encryption_set_key_vault_to_key_edge,
        edge.azure_compute_disk_to_compute_snapshot_edge
      ]

      args = {
        id = self.input.disk_id.value
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
        query = query.azure_compute_disk_overview
        args = {
          id = self.input.disk_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_compute_virtual_machine_tags
        args = {
          id = self.input.disk_id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Associated Virtual Machine"
        query = query.azure_compute_disk_associated_virtual_machine_details
        args = {
          id = self.input.disk_id.value
        }

        column "Title" {
          href = "${dashboard.azure_compute_virtual_machine_detail.url_path}?input.vm_id={{.ID | @uri}}"
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Disk Encryption"
      query = query.azure_compute_disk_encryption_set_details
      args = {
        id = self.input.disk_id.value
      }
    }
  }
}

query "azure_compute_disk_input" {
  sql = <<-EOQ
    select
      d.title as label,
      d.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', d.resource_group,
        'region', d.region
      ) as tags
    from
      azure_compute_disk as d,
      azure_subscription as s
    where
      d.subscription_id = s.subscription_id
    order by
      d.title;
  EOQ
}

query "azure_compute_disk_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      disk_state as value
    from
      azure_compute_disk
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_compute_disk_os_type" {
  sql = <<-EOQ
    select
      'OS Type' as label,
      os_type as value
    from
      azure_compute_disk
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_disk_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_compute_disk
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_disk_encryption_status" {
  sql = <<-EOQ
    select
      'Host Encryption' as label,
      case when encryption_settings_collection_enabled <> 'true' then 'Disabled' else 'Enabled' end as value,
      case when encryption_settings_collection_enabled <> 'true' then 'alert' else 'ok' end as type
    from
      azure_compute_disk
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_disk_node" {
  category = category.azure_compute_disk

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
      azure_compute_disk
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_disk_from_compute_virtual_machine_node" {
  category = category.azure_compute_virtual_machine

  sql = <<-EOQ
    with vm_disk_id as (
      select
        id,
        title,
        name,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements(data_disks)->'managedDisk'->>'id' as did
      from
        azure_compute_virtual_machine
    )
    select
      v.id as id,
      v.title as title,
      jsonb_build_object(
        'Name', v.name,
        'ID', v.id,
        'Subscription ID',v.subscription_id,
        'Resource Group', v.resource_group,
        'Region', v.region
      ) as properties
    from
      vm_disk_id as v
      left join azure_compute_disk as d on v.did = d.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_disk_from_compute_virtual_machine_edge" {
  title = "virtual machine"

  sql = <<-EOQ
    with vm_disk_id as (
      select
        id,
        title,
        name,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements(data_disks)->'managedDisk'->>'id' as did
      from
        azure_compute_virtual_machine
    )
    select
      v.id as from_id,
      d.id as to_id
    from
      vm_disk_id as v
      left join azure_compute_disk as d on v.did = d.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_disk_to_compute_disk_encryption_set_node" {
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
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_disk_to_compute_disk_encryption_set_edge" {
  title = "disk encryption set"

  sql = <<-EOQ
    select
      d.id as from_id,
      e.id as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_disk_compute_disk_encryption_set_to_key_vault_node" {
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
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
      left join azure_key_vault as k on e.active_key_source_vault_id = k.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_disk_compute_disk_encryption_set_to_key_vault_edge" {
  title = "key vault"

  sql = <<-EOQ
    select
      e.id as from_id,
      k.id as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
      left join azure_key_vault as k on e.active_key_source_vault_id = k.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_disk_compute_disk_encryption_set_key_vault_to_key_node" {
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
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
      left join azure_key_vault_key as k on e.active_key_url = k.key_uri_with_version
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_disk_compute_disk_encryption_set_key_vault_to_key_edge" {
  title = "key"

  sql = <<-EOQ
    select
      e.active_key_source_vault_id as from_id,
      k.id as to_id
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
      left join azure_key_vault_key as k on e.active_key_url = k.key_uri_with_version
    where
      d.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_disk_to_compute_snapshot_node" {
  category = category.azure_compute_snapshot

  sql = <<-EOQ
    select
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group,
        'Region', s.region
      ) as properties
    from
      azure_compute_snapshot as s
      left join azure_compute_disk as d on s.source_resource_id = d.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_disk_to_compute_snapshot_edge" {
  title = "snapshot"

  sql = <<-EOQ
    select
      d.id as from_id,
      s.id as to_id
    from
      azure_compute_snapshot as s
      left join azure_compute_disk as d on s.source_resource_id = d.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_disk_overview" {
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
      id = $1
  EOQ

  param "id" {}
}

query "azure_compute_disk_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_compute_disk
    where
      id = $1
    order by
      tags ->> 'Key';
    EOQ

  param "id" {}
}

query "azure_compute_disk_associated_virtual_machine_details" {
  sql = <<-EOQ
    with vm_disk_id as (
      select
        id,
        type,
        title,
        jsonb_array_elements(data_disks)->'managedDisk'->>'id' as did
      from
        azure_compute_virtual_machine
    )
    select
      v.title as "Title",
      v.type as  "Type",
      v.id as "ID"
    from
      vm_disk_id as v
      left join azure_compute_disk as d on v.did = d.id
    where
      d.id = $1
  EOQ

  param "id" {}
}

query "azure_compute_disk_encryption_set_details" {
  sql = <<-EOQ
    select
      e.name as "Name",
      e.type as "Type",
      e.active_key_source_vault_id as "Key Vault ID",
      e.active_key_url as "Key URI",
      e.id as "ID"
    from
      azure_compute_disk_encryption_set as e
      left join azure_compute_disk as d on d.encryption_disk_encryption_set_id = e.id
    where
      d.id = $1;
  EOQ

  param "id" {}
}