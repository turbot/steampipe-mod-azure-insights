dashboard "azure_kubernetes_cluster_detail" {

  title         = "Azure Kubernetes Cluster Detail"
  documentation = file("./dashboards/kubernetes/docs/kubernetes_cluster_detail.md")

  tags = merge(local.kubernetes_common_tags, {
    type = "Detail"
  })

  input "cluster_id" {
    title = "Select a cluster:"
    query = query.azure_kubernetes_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_kubernetes_cluster_status
      args = {
        id = self.input.cluster_id.value
      }
    }

    card {
      width = 2
      query = query.azure_kubernetes_cluster_version
      args = {
        id = self.input.cluster_id.value
      }
    }

    card {
      width = 2
      query = query.azure_kubernetes_cluster_node_pool_count
      args = {
        id = self.input.cluster_id.value
      }
    }

    card {
      width = 2
      query = query.azure_kubernetes_cluster_disk_encryption_status
      args = {
        id = self.input.cluster_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.kubernetes_cluster,
        node.azure_kubernetes_cluster_to_node_pool_node,
        node.azure_kubernetes_cluster_to_compute_disk_encryption_set_node,
        node.azure_kubernetes_cluster_to_virtual_machine_scale_set_node,
        node.azure_kubernetes_cluster_virtual_machine_scale_set_to_vm_node
      ]

      edges = [
        edge.azure_kubernetes_cluster_to_node_pool_edge,
        edge.azure_kubernetes_cluster_to_compute_disk_encryption_set_edge,
        edge.azure_kubernetes_cluster_to_virtual_machine_scale_set_edge,
        edge.azure_kubernetes_cluster_virtual_machine_scale_set_to_vm_edge
      ]

      args = {
        kubernetes_cluster_ids = [self.input.cluster_id.value]
        id                     = self.input.cluster_id.value
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
        query = query.azure_kubernetes_cluster_overview
        args = {
          id = self.input.cluster_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_kubernetes_cluster_tags
        args = {
          id = self.input.cluster_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Node Pool Details"
        query = query.azure_kubernetes_cluster_agent_pools
        args = {
          id = self.input.cluster_id.value
        }
      }

      table {
        title = "Disk Encryption Set Details"
        query = query.azure_kubernetes_cluster_disk_encryption_details
        args = {
          id = self.input.cluster_id.value
        }
      }
    }

  }

}

query "azure_kubernetes_cluster_input" {
  sql = <<-EOQ
    select
      c.title as label,
      c.id as value,
      json_build_object(
        'Subscription', s.display_name,
        'Resource Group', c.resource_group,
        'Region', c.region,
        'ID', c.id
      ) as tags
    from
      azure_kubernetes_cluster as c,
      azure_subscription as s
    where
      lower(c.subscription_id) = lower(s.subscription_id)
    order by
      c.title;
  EOQ
}

query "azure_kubernetes_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      power_state ->> 'code' as value
    from
      azure_kubernetes_cluster
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_kubernetes_cluster_version" {
  sql = <<-EOQ
    select
      'Kubernetes Version' as label,
      kubernetes_version as value
    from
      azure_kubernetes_cluster
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_kubernetes_cluster_node_pool_count" {
  sql = <<-EOQ
    select
      'Node Pools' as label,
      jsonb_array_length(agent_pool_profiles) as value
    from
      azure_kubernetes_cluster
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_kubernetes_cluster_disk_encryption_status" {
  sql = <<-EOQ
    select
      'Disk Encryption' as label,
      case when disk_encryption_set_id is null then 'Disabled' else 'Enabled' end as value,
      case when disk_encryption_set_id is null then 'alert' else 'ok' end as type
    from
      azure_kubernetes_cluster
    where
      id = $1;
  EOQ

  param "id" {}
}

node "kubernetes_cluster" {
  category = category.kubernetes_cluster

  sql = <<-EOQ
    select
      lower(id),
      title,
      jsonb_build_object(
        'ID', ID,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Provisioning State', provisioning_state,
        'Type', type,
        'Kubernetes Version', kubernetes_version,
        'Region', region
      ) as properties
    from
      azure_kubernetes_cluster
    where
      lower(id) = any($1);
  EOQ

  param "kubernetes_cluster_ids" {}
}

node "azure_kubernetes_cluster_to_node_pool_node" {
  category = category.kubernetes_node_pool

  sql = <<-EOQ
    select
      p ->> 'name' as id,
      p ->> 'name' as title,
      jsonb_build_object(
        'Name', p ->> 'name',
        'Node Count', p ->> 'count',
        'Autoscaling Enabled' , p ->> 'enableAutoScaling',
        'Is Public', p ->> 'enableNodePublicIP',
        'OS Disk Size(GB)', p ->> 'osDiskSizeGB',
        'OS Disk Type', p ->> 'osDiskType',
        'OS Disk Type', p ->> 'osDiskType',
        'OS Type', p ->> 'osType',
        'VM Size', p ->> 'vmSize'
      ) as properties
    from
      azure_kubernetes_cluster c,
      jsonb_array_elements(agent_pool_profiles) p
    where
      c.id = $1;
  EOQ

  param "id" {}
}

edge "azure_kubernetes_cluster_to_node_pool_edge" {
  title = "node pool"

  sql = <<-EOQ
    select
      c.id as from_id,
      p ->> 'name' as to_id
    from
      azure_kubernetes_cluster c,
      jsonb_array_elements(agent_pool_profiles) p
    where
      c.id = $1;
  EOQ

  param "id" {}
}

node "azure_kubernetes_cluster_to_compute_disk_encryption_set_node" {
  category = category.compute_disk_encryption_set

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
      azure_kubernetes_cluster c,
      azure_compute_disk_encryption_set e
    where
      lower(c.disk_encryption_set_id) = lower(e.id)
      and c.id = $1;
  EOQ

  param "id" {}
}

edge "azure_kubernetes_cluster_to_compute_disk_encryption_set_edge" {
  title = "disk encryption set"

  sql = <<-EOQ
    select
      c.id as from_id,
      e.id as to_id
    from
      azure_kubernetes_cluster c,
      azure_compute_disk_encryption_set e
    where
      lower(c.disk_encryption_set_id) = lower(e.id)
      and c.id = $1;
  EOQ

  param "id" {}
}

node "azure_kubernetes_cluster_to_virtual_machine_scale_set_node" {
  category = category.compute_virtual_machine_scale_set

  sql = <<-EOQ
    select
      set.id as id,
      set.title as title,
      jsonb_build_object(
        'ID', set.id,
        'Name', set.name,
        'Type', set.type,
        'Resource Group', set.resource_group,
        'Subscription ID', set.subscription_id
      ) as properties
    from
      azure_kubernetes_cluster c,
      azure_compute_virtual_machine_scale_set as set
    where
      lower(set.resource_group) = lower(c.node_resource_group)
      and c.id = $1;
  EOQ

  param "id" {}
}

edge "azure_kubernetes_cluster_to_virtual_machine_scale_set_edge" {
  title = "vm scale set"

  sql = <<-EOQ
    select
      c.id as from_id,
      set.id as to_id
    from
      azure_kubernetes_cluster c,
      azure_compute_virtual_machine_scale_set set
    where
      lower(set.resource_group) = lower(c.node_resource_group)
      and c.id = $1;
  EOQ

  param "id" {}
}

node "azure_kubernetes_cluster_virtual_machine_scale_set_to_vm_node" {
  category = category.compute_virtual_machine_scale_set_vm

  sql = <<-EOQ
    select
      vm.id as id,
      vm.title as title,
      jsonb_build_object(
        'Name', vm.name,
        'ID', vm.id,
        'Instance ID', vm.instance_id,
        'SKU Name', vm.sku_name,
        'Provisioning State', vm.provisioning_state,
        'Type', vm.type,
        'Subscription ID', vm.subscription_id,
        'Resource Group', vm.resource_group,
        'Provisioning State', vm.provisioning_state,
        'Region', vm.region
      ) as properties
    from
      azure_kubernetes_cluster c,
      azure_compute_virtual_machine_scale_set set,
      azure_compute_virtual_machine_scale_set_vm vm
    where
      lower(set.resource_group) = lower(c.node_resource_group)
      and set.name = vm.scale_set_name
      and vm.resource_group = set.resource_group
      and c.id = $1;
  EOQ

  param "id" {}
}

edge "azure_kubernetes_cluster_virtual_machine_scale_set_to_vm_edge" {
  title = "instance"

  sql = <<-EOQ
    select
      set.id as from_id,
      vm.id as to_id
    from
      azure_kubernetes_cluster c,
      azure_compute_virtual_machine_scale_set set,
      azure_compute_virtual_machine_scale_set_vm vm
    where
      lower(set.resource_group) = lower(c.node_resource_group)
      and set.name = vm.scale_set_name
      and vm.resource_group = set.resource_group
      and c.id = $1;
  EOQ

  param "id" {}
}

query "azure_kubernetes_cluster_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "Virtual Machine ID",
      type as "Type",
      provisioning_state as "Provisioning State",
      dns_prefix as "DNS Prefix",
      identity ->> 'type' as "Identity Type",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_kubernetes_cluster
    where
      id = $1
  EOQ

  param "id" {}
}

query "azure_kubernetes_cluster_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_kubernetes_cluster,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_kubernetes_cluster_agent_pools" {
  sql = <<-EOQ
    select
      p ->> 'name' as "Name",
      p ->> 'count' as "Node Count",
      p ->> 'enableAutoScaling' as "Autoscaling Enabled",
      p ->> 'enableNodePublicIP' as "Is Public",
      p ->> 'osDiskSizeGB' as "OS Disk Size(GB)",
      p ->> 'osDiskType' as "OS Disk Type",
      p ->> 'osDiskType' as "OS Disk Type",
      p ->> 'osType' as "OS Type",
      p ->> 'vmSize' as "VM Size"
    from
      azure_kubernetes_cluster c,
      jsonb_array_elements(c.agent_pool_profiles) p
    where
      id = $1
  EOQ

  param "id" {}
}

query "azure_kubernetes_cluster_disk_encryption_details" {
  sql = <<-EOQ
    select
      e.name as "Name",
      e.active_key_url as "Active Key URL",
      e.cloud_environment as "Cloud Environment",
      e.encryption_type as "Encryption Type",
      e.identity_type as "Identity Type",
      e.provisioning_state as "Provisioning State",
      e.resource_group as "Resource Group"
    from
      azure_kubernetes_cluster c,
      azure_compute_disk_encryption_set e
    where
      lower(c.disk_encryption_set_id) = lower(e.id)
      and c.id = $1;
  EOQ

  param "id" {}
}
