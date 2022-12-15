dashboard "kubernetes_cluster_detail" {

  title         = "Azure Kubernetes Cluster Detail"
  documentation = file("./dashboards/kubernetes/docs/kubernetes_cluster_detail.md")

  tags = merge(local.kubernetes_common_tags, {
    type = "Detail"
  })

  input "cluster_id" {
    title = "Select a cluster:"
    query = query.kubernetes_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.kubernetes_cluster_status
      args  = [self.input.cluster_id.value]
    }

    card {
      width = 2
      query = query.kubernetes_cluster_version
      args  = [self.input.cluster_id.value]
    }

    card {
      width = 2
      query = query.kubernetes_cluster_node_pool_count
      args  = [self.input.cluster_id.value]
    }

    card {
      width = 2
      query = query.kubernetes_cluster_disk_encryption_status
      args  = [self.input.cluster_id.value]
    }

  }

  with "compute_disk_encryption_sets" {
    query = query.kubernetes_cluster_compute_disk_encryption_sets
    args  = [self.input.cluster_id.value]
  }

  with "compute_virtual_machine_scale_sets" {
    query = query.kubernetes_cluster_compute_virtual_machine_scale_sets
    args  = [self.input.cluster_id.value]
  }

  with "compute_virtual_machine_scale_set_vms" {
    query = query.kubernetes_cluster_compute_virtual_machine_scale_set_vms
    args  = [self.input.cluster_id.value]
  }


  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.compute_disk_encryption_set
        args = {
          compute_disk_encryption_set_ids = with.compute_disk_encryption_sets.rows[*].encryption_set_id
        }
      }

      node {
        base = node.compute_virtual_machine_scale_set
        args = {
          compute_virtual_machine_scale_set_ids = with.compute_virtual_machine_scale_sets.rows[*].scale_set_id
        }
      }

      node {
        base = node.compute_virtual_machine_scale_set_vm
        args = {
          compute_virtual_machine_scale_set_vm_ids = with.compute_virtual_machine_scale_set_vms.rows[*].vm_id
        }
      }

      node {
        base = node.kubernetes_cluster
        args = {
          kubernetes_cluster_ids = [self.input.cluster_id.value]
        }
      }

      node {
        base = node.kubernetes_node_pool
        args = {
          kubernetes_cluster_ids = [self.input.cluster_id.value]
        }
      }

      edge {
        base = edge.kubernetes_cluster_to_compute_disk_encryption_set
        args = {
          kubernetes_cluster_ids = [self.input.cluster_id.value]
        }
      }

      edge {
        base = edge.kubernetes_cluster_to_compute_virtual_machine_scale_set
        args = {
          kubernetes_cluster_ids = [self.input.cluster_id.value]
        }
      }

      edge {
        base = edge.kubernetes_cluster_to_compute_virtual_machine_scale_set_vm
        args = {
          kubernetes_cluster_ids = [self.input.cluster_id.value]
        }
      }

      edge {
        base = edge.kubernetes_cluster_to_kubernetes_node_pool
        args = {
          kubernetes_cluster_ids = [self.input.cluster_id.value]
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
        query = query.kubernetes_cluster_overview
        args  = [self.input.cluster_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.kubernetes_cluster_tags
        args  = [self.input.cluster_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "Node Pool Details"
        query = query.kubernetes_cluster_agent_pools
        args  = [self.input.cluster_id.value]
      }

      table {
        title = "Disk Encryption Set Details"
        query = query.kubernetes_cluster_disk_encryption_details
        args  = [self.input.cluster_id.value]
      }
    }

  }

}

query "kubernetes_cluster_input" {
  sql = <<-EOQ
    select
      c.title as label,
      lower(c.id) as value,
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

#card queries

query "kubernetes_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      power_state ->> 'code' as value
    from
      azure_kubernetes_cluster
    where
      lower(id) = $1;
  EOQ

}

query "kubernetes_cluster_version" {
  sql = <<-EOQ
    select
      'Kubernetes Version' as label,
      kubernetes_version as value
    from
      azure_kubernetes_cluster
    where
      lower(id) = $1;
  EOQ

}

query "kubernetes_cluster_node_pool_count" {
  sql = <<-EOQ
    select
      'Node Pools' as label,
      jsonb_array_length(agent_pool_profiles) as value
    from
      azure_kubernetes_cluster
    where
      lower(id) = $1;
  EOQ

}

query "kubernetes_cluster_disk_encryption_status" {
  sql = <<-EOQ
    select
      'Disk Encryption' as label,
      case when disk_encryption_set_id is null then 'Disabled' else 'Enabled' end as value,
      case when disk_encryption_set_id is null then 'alert' else 'ok' end as type
    from
      azure_kubernetes_cluster
    where
      lower(id) = $1;
  EOQ

}

# with queries

query "kubernetes_cluster_compute_disk_encryption_sets" {
  sql   = <<-EOQ
    select
      lower(e.id) as encryption_set_id
    from
      azure_kubernetes_cluster c,
      azure_compute_disk_encryption_set e
    where
      lower(c.disk_encryption_set_id) = lower(e.id)
      and lower(c.id) = $1;
  EOQ
}

query "kubernetes_cluster_compute_virtual_machine_scale_sets" {
  sql   = <<-EOQ
    select
      lower(set.id) as scale_set_id
    from
      azure_kubernetes_cluster c,
      azure_compute_virtual_machine_scale_set as set
    where
      lower(set.resource_group) = lower(c.node_resource_group)
      and lower(c.id) = $1;
  EOQ
}

query "kubernetes_cluster_compute_virtual_machine_scale_set_vms" {
  sql   = <<-EOQ
    select
      lower(vm.id) as vm_id
    from
      azure_kubernetes_cluster c,
      azure_compute_virtual_machine_scale_set set,
      azure_compute_virtual_machine_scale_set_vm vm
    where
      lower(set.resource_group) = lower(c.node_resource_group)
      and set.name = vm.scale_set_name
      and vm.resource_group = set.resource_group
      and lower(c.id) = $1;
  EOQ
}

# table queries

query "kubernetes_cluster_overview" {
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
      lower(id) = $1
  EOQ

}

query "kubernetes_cluster_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_kubernetes_cluster,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
    EOQ

}

query "kubernetes_cluster_agent_pools" {
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
      lower(id) = $1
  EOQ

}

query "kubernetes_cluster_disk_encryption_details" {
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
      and lower(c.id) = $1;
  EOQ

}
