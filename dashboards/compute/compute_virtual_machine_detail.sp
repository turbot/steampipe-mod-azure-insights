dashboard "compute_virtual_machine_detail" {

  title         = "Azure Compute Virtual Machine Detail"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "vm_id" {
    title = "Select a virtual machine:"
    query = query.compute_virtual_machine_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.compute_virtual_machine_status
      args  = [self.input.vm_id.value]
    }

    card {
      width = 2
      query = query.compute_virtual_machine_encryption_status
      args  = [self.input.vm_id.value]
    }

    card {
      width = 2
      query = query.compute_virtual_machine_disaster_recovery_status
      args  = [self.input.vm_id.value]
    }

    card {
      width = 2
      query = query.compute_virtual_machine_ingress_access
      args  = [self.input.vm_id.value]
    }

    card {
      width = 2
      query = query.compute_virtual_machine_vulnerability_assessment_solution
      args  = [self.input.vm_id.value]
    }
  }

  with "compute_disks_for_compute_virtual_machine" {
    query = query.compute_disks_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "compute_images_for_compute_virtual_machine" {
    query = query.compute_images_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_application_gateways_for_compute_virtual_machine" {
    query = query.network_application_gateways_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_load_balancer_backend_address_pools_for_compute_virtual_machine" {
    query = query.network_load_balancer_backend_address_pools_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_load_balancers_for_compute_virtual_machine" {
    query = query.network_load_balancers_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_network_interfaces_for_compute_virtual_machine" {
    query = query.network_network_interfaces_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_public_ips_for_compute_virtual_machine" {
    query = query.network_public_ips_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_security_groups_for_compute_virtual_machine" {
    query = query.network_security_groups_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_subnets_for_compute_virtual_machine" {
    query = query.network_subnets_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  with "network_virtual_networks_for_compute_virtual_machine" {
    query = query.network_virtual_networks_for_compute_virtual_machine
    args  = [self.input.vm_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      node {
        base = node.compute_disk
        args = {
          compute_disk_ids = with.compute_disks_for_compute_virtual_machine.rows[*].disk_id
        }
      }

      node {
        base = node.compute_image
        args = {
          compute_image_ids = with.compute_images_for_compute_virtual_machine.rows[*].compute_image_id
        }
      }

      node {
        base = node.compute_virtual_machine
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      node {
        base = node.compute_virtual_machine_application_gateway_backend_address_pool
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      node {
        base = node.network_application_gateway
        args = {
          network_application_gateway_ids = with.network_application_gateways_for_compute_virtual_machine.rows[*].application_gateway_id
        }
      }

      node {
        base = node.network_load_balancer
        args = {
          network_load_balancer_ids = with.network_load_balancers_for_compute_virtual_machine.rows[*].load_balancer_id
        }
      }

      node {
        base = node.network_load_balancer_backend_address_pool
        args = {
          network_load_balancer_backend_address_pool_ids = with.network_load_balancer_backend_address_pools_for_compute_virtual_machine.rows[*].pool_id
        }
      }

      node {
        base = node.network_network_interface
        args = {
          network_network_interface_ids = with.network_network_interfaces_for_compute_virtual_machine.rows[*].network_interface_id
        }
      }

      node {
        base = node.network_network_security_group
        args = {
          network_network_security_group_ids = with.network_security_groups_for_compute_virtual_machine.rows[*].nsg_id
        }
      }

      node {
        base = node.network_public_ip
        args = {
          network_public_ip_ids = with.network_public_ips_for_compute_virtual_machine.rows[*].public_ip_id
        }
      }

      node {
        base = node.network_subnet
        args = {
          network_subnet_ids = with.network_subnets_for_compute_virtual_machine.rows[*].subnet_id
        }
      }

      node {
        base = node.network_virtual_network
        args = {
          network_virtual_network_ids = with.network_virtual_networks_for_compute_virtual_machine.rows[*].virtual_network_id
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_compute_data_disk
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_compute_image
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_compute_os_disk
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_network_network_interface
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_network_public_ip
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_network_security_group
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_network_subnet
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_network_virtual_network
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.network_application_gateway_backend_address_pool_to_compute_virtual_machine
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.network_application_gateway_to_compute_virtual_machine
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.network_load_balancer_backend_address_pool_to_compute_virtual_machine
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
        }
      }

      edge {
        base = edge.network_load_balancer_to_compute_virtual_machine_backend_address_pool
        args = {
          compute_virtual_machine_ids = [self.input.vm_id.value]
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
        query = query.compute_virtual_machine_overview
        args  = [self.input.vm_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_virtual_machine_tags
        args  = [self.input.vm_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "Storage Profile"
        query = query.compute_virtual_machine_storage_profile
        args  = [self.input.vm_id.value]

        column "Disk Name" {
          href = "/azure_insights.dashboard.compute_disk_detail?input.disk_id={{ .ID | @uri }}"
        }
      }

      table {
        title = "Image"
        query = query.compute_virtual_machine_image
        args  = [self.input.vm_id.value]
      }
    }

  }

  container {
    width = 12

    table {
      title = "Security Groups"
      query = query.compute_virtual_machine_security_groups
      args  = [self.input.vm_id.value]

      column "Name" {
        href = "/azure_insights.dashboard.network_security_group_detail?input.nsg_id={{ .'Security Group ID' | @uri }}"
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.compute_virtual_machine_network_interfaces
      args  = [self.input.vm_id.value]

      column "Name" {
        href = "/azure_insights.dashboard.network_interface_detail?input.nic_id={{ .'Network Interface ID' | @uri }}"
      }
    }

  }

  container {
    width = 12

    table {
      title = "Guest Configuration"
      query = query.compute_virtual_machine_guest_configuration_assignments
      args  = [self.input.vm_id.value]
    }

  }

  container {
    width = 12

    table {
      title = "Data Disks"
      query = query.compute_virtual_machine_data_disks
      args  = [self.input.vm_id.value]

      column "Name" {
        href = "/azure_insights.dashboard.compute_disk_detail?input.disk_id={{ .'Managed Disk ID' | @uri }}"
      }
    }

  }

}

query "compute_virtual_machine_input" {
  sql = <<-EOQ
    select
      v.title as label,
      lower(v.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', v.resource_group,
        'region', v.region,
        'vm_id', v.vm_id
      ) as tags
    from
      azure_compute_virtual_machine as v,
      azure_subscription as s
    where
      v.subscription_id = s.subscription_id
    order by
      v.title;
  EOQ
}

# Card Queries

query "compute_virtual_machine_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(power_state) as value
    from
      azure_compute_virtual_machine
    where
      lower(id) = $1;
  EOQ
}

query "compute_virtual_machine_encryption_status" {
  sql = <<-EOQ
    select
      'Host Encryption' as label,
      case when security_profile -> 'encryptionAtHost' <> 'true' or security_profile -> 'encryptionAtHost' is null then 'Disabled' else 'Enabled' end as value,
      case when security_profile -> 'encryptionAtHost' <> 'true' or security_profile -> 'encryptionAtHost' is null then 'alert' else 'ok' end as type
    from
      azure_compute_virtual_machine
    where
      lower(id) = $1;
  EOQ
}

query "compute_virtual_machine_disaster_recovery_status" {
  sql = <<-EOQ
    with vm_dr_enabled as (
      select
        substr(source_id, 0, length(source_id)) as source_id
      from
        azure_resource_link as l
        left join azure_compute_virtual_machine as vm on lower(substr(source_id, 0, length(source_id)))= lower(vm.id)
      where
        l.name like 'ASR-Protect-%'
    )
    select
      'Disaster Recovery' as label,
      case when source_id is null then 'Disabled' else 'Enabled' end as value,
      case when source_id is null then 'alert' else 'ok' end as type
    from
      azure_compute_virtual_machine as vm
      left join vm_dr_enabled as l on lower(vm.id) = lower(l.source_id)
    where
      lower(id) = $1;
  EOQ
}

query "compute_virtual_machine_ingress_access" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name as sg_name,
        network_interfaces
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(security_rules) as sg,
        jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) as dport,
        jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Inbound'
        and sg -> 'properties' ->> 'protocol' in ('TCP','*')
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
    )
    select
      'Unrestricted Ingress' as label,
      case when sg.sg_name is null then 'Restricted' else 'Unrestricted' end as value,
      case when sg.sg_name is null then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine as vm
      left join network_sg as sg on sg.network_interfaces @> vm.network_interfaces
    where
      lower(id) = $1;
  EOQ
}

query "azure_compute_virtual_machine_egress_access" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name as sg_name,
        network_interfaces
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(security_rules) as sg,
        jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) as dport,
        jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Outbound'
        and sg -> 'properties' ->> 'protocol' in ('TCP','*')
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', '<nw>/0', '/0')
    )
    select
      'Unrestricted Egress' as label,
      case when sg.sg_name is null then 'Restricted' else 'Unrestricted' end as value,
      case when sg.sg_name is null then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine as vm
      left join network_sg as sg on sg.network_interfaces @> vm.network_interfaces
    where
      lower(id) = $1;
  EOQ
}

query "compute_virtual_machine_vulnerability_assessment_solution" {
  sql = <<-EOQ
    with defender_enabled_vms as (
      select
        distinct a.vm_id as vm_id
      from
        azure_compute_virtual_machine as a,
        jsonb_array_elements(extensions) as b
      where
        b ->> 'ExtensionType' = any(ARRAY ['MDE.Linux', 'MDE.Windows'])
        and b ->> 'ProvisioningState' = 'Succeeded'
    ),
    agent_installed_vm as (
      select
        distinct a.vm_id as vm_id
      from
        defender_enabled_vms as a
        left join azure_compute_virtual_machine as w on lower(w.vm_id) = lower(a.vm_id),
        jsonb_array_elements(extensions) as b
      where
        b ->> 'Publisher' = 'Qualys'
        and b ->> 'ExtensionType' = any(ARRAY ['WindowsAgent.AzureSecurityCenter', 'LinuxAgent.AzureSecurityCenter'])
        and b ->> 'ProvisioningState' = 'Succeeded'
    )
    select
      'Vulnerability Assessment' as label,
      case when b.vm_id is not null then 'Enabled' else 'Disabled' end as value,
      case when b.vm_id is not null then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine as a
      left join agent_installed_vm as b on lower(a.vm_id) = lower(b.vm_id)
    where
      lower(id) = $1;
  EOQ
}

# With Queries

query "compute_disks_for_compute_virtual_machine" {
  sql = <<-EOQ
    select
      lower(jsonb_array_elements(data_disks)->'managedDisk'->>'id') as disk_id
    from
      azure_compute_virtual_machine
    where
      lower(id) = $1
    union
    select
      lower(d.id) as disk_id
    from
      azure_compute_virtual_machine as vm
      left join azure_compute_disk as d on lower(d.managed_by) = lower(vm.id)
    where
      lower(vm.id) = $1;
  EOQ
}

query "compute_images_for_compute_virtual_machine" {
  sql = <<-EOQ
    select
      lower(i.id) as compute_image_id
    from
      azure_compute_image as i
      left join azure_compute_virtual_machine as v on lower(i.id) = lower(v.image_id)
    where
      lower(v.id) = $1;
  EOQ
}

query "network_application_gateways_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interface as (
      select
        vm.id,
        nic.id,
        nic.ip_configurations as ip_configurations
      from
        azure_compute_virtual_machine as vm,
        jsonb_array_elements(network_interfaces) as n
        left join azure_network_interface as nic on nic.id = n ->> 'id'
      where
        lower(vm.id) = $1
    ),
    vm_application_gateway_backend_address_pool as (
      select
        p ->> 'id' as id
      from
        network_interface,
        jsonb_array_elements(ip_configurations) as i,
        jsonb_array_elements(i -> 'properties' -> 'applicationGatewayBackendAddressPools') as p
    )
    select
      lower(g.id) as application_gateway_id
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
    where
      lower(p ->> 'id') in (select lower(id) from vm_application_gateway_backend_address_pool);
  EOQ
}

query "network_load_balancer_backend_address_pools_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interface as (
      select
        vm.id,
        nic.id,
        nic.ip_configurations as ip_configurations
      from
        azure_compute_virtual_machine as vm,
        jsonb_array_elements(network_interfaces) as n
        left join azure_network_interface as nic on nic.id = n ->> 'id'
      where
        lower(vm.id) = $1
    ),
    loadBalancerBackendAddressPools as (
      select
        p ->> 'id' as id
      from
        network_interface,
        jsonb_array_elements(ip_configurations) as i,
        jsonb_array_elements(i -> 'properties' -> 'loadBalancerBackendAddressPools') as p
    )
    select
      lower(pool.id) as pool_id
    from
      loadBalancerBackendAddressPools as p
      left join azure_lb_backend_address_pool as pool on lower(pool.id) = lower(p.id);
  EOQ
}

query "network_load_balancers_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interface as (
      select
        vm.id,
        nic.id,
        nic.ip_configurations as ip_configurations
      from
        azure_compute_virtual_machine as vm,
        jsonb_array_elements(network_interfaces) as n
        left join azure_network_interface as nic on nic.id = n ->> 'id'
      where
        lower(vm.id) = $1
    ),
    loadBalancerBackendAddressPools as (
      select
        p ->> 'id' as id
      from
        network_interface,
        jsonb_array_elements(ip_configurations) as i,
        jsonb_array_elements(i -> 'properties' -> 'loadBalancerBackendAddressPools') as p
    )
    select
      lower(lb.id) as load_balancer_id
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as pool
    where
      lower(pool ->> 'id') in (select lower(id) from loadBalancerBackendAddressPools);
  EOQ
}

query "network_network_interfaces_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interface_id as (
      select
        id as vm_id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
      where
        lower(id) = $1
    )
    select
      lower(vn.n_id) as network_interface_id
    from
      network_interface_id as vn
      left join azure_network_interface as n on lower(vn.n_id) = lower(n.id)
  EOQ
}

query "network_public_ips_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interfaces as (
      select
        vm.id as vm_id,
        nic.id as nic_id,
        nic.ip_configurations as ip_configuration
      from
        azure_compute_virtual_machine as vm,
        jsonb_array_elements(network_interfaces) as n
        left join azure_network_interface as nic on lower(nic.id) = lower(n ->> 'id')
      where
        lower(vm.id) = $1
    )
    select
      lower(p.id) as public_ip_id
    from
      network_interfaces as n,
      jsonb_array_elements(ip_configuration) as ip_config
      left join azure_public_ip as p on lower(p.id) = lower(ip_config -> 'properties' -> 'publicIPAddress' ->> 'id')
    where
      p.id is not null;
  EOQ
}

query "network_security_groups_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interface_id as (
      select
        id as vm_id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
      where
        lower(id) = $1
    )
    select
      lower(s.id) as nsg_id
    from
      network_interface_id as vn
      left join azure_network_interface as n on lower(vn.n_id) = lower(n.id)
      left join azure_network_security_group as s on lower(n.network_security_group_id) = lower(s.id)
    where
      s.id is not null
  EOQ
}

query "network_subnets_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces) ->> 'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        lower(id) = $1
    )
    select
      lower(s.id) as subnet_id
    from
      azure_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
    where
      lower(nic.id) in (select lower(nic_id) from network_interface_id);
  EOQ
}

query "network_virtual_networks_for_compute_virtual_machine" {
  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        lower(id) = $1
    ), subnet_id as (
        select
          s.id as id,
          s.virtual_network_name
        from
          azure_network_interface as nic,
          jsonb_array_elements(ip_configurations) as c
          left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
        where
          lower(nic.id) in (select lower(nic_id) from network_interface_id)
    )
    select
      lower(vn.id) as virtual_network_id
    from
      azure_virtual_network as vn,
      jsonb_array_elements(subnets) as s
      left join subnet_id as sub on lower(sub.id) = lower(s ->> 'id')
    where
      lower(s ->> 'id') in (select lower(id) from subnet_id);
  EOQ
}

# Table Queries

query "compute_virtual_machine_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      vm_id as "Virtual Machine ID",
      type as "Type",
      provisioning_state as "Provisioning State",
      size as "Size",
      os_type as "OS Type",
      identity ->> 'type' as "Identity",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_compute_virtual_machine
    where
      lower(id) = $1;
  EOQ
}

query "compute_virtual_machine_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_compute_virtual_machine,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
    EOQ
}

query "compute_virtual_machine_storage_profile" {
  sql = <<-EOQ
    select
      os_disk_name as "Disk Name",
      os_disk_caching as "Disk Caching",
      os_disk_create_option as "Disk Create Option",
      os_disk_vhd_uri as "Virtual Hard Disk URI",
      lower(d.id) as "ID"
    from
      azure_compute_virtual_machine as vm
      left join azure_compute_disk as d on  vm.os_disk_name = d.name  and lower(vm.id)= lower(d.managed_by)
    where
      lower(vm.id) = $1;
  EOQ
}

query "compute_virtual_machine_image" {
  sql = <<-EOQ
    select
      image_sku as "SKU",
      image_version as "Version",
      image_exact_version as "Exact Version",
      image_id as "Image ID",
      image_offer as "Offer",
      image_publisher as "Publisher"
    from
      azure_compute_virtual_machine
    where
      lower(id) = $1;
  EOQ
}

query "compute_virtual_machine_security_groups" {
  sql = <<-EOQ
    select
      nsg.name as "Name",
      nsg.provisioning_state as "Provisioning State",
      nsg.region as "Region",
      nsg.resource_group as "Resource Group",
      lower(nsg.id) as "Security Group ID"
    from
      azure_network_security_group as nsg
      left join azure_compute_virtual_machine as vm on vm.network_interfaces @> nsg.network_interfaces
    where
      lower(vm.id) = $1;
  EOQ
}

query "compute_virtual_machine_data_disks" {
  sql = <<-EOQ
    select
      disk ->> 'name' as "Name",
      disk ->> 'caching' as "Caching",
      disk ->> 'createOption' as "Create Option",
      (disk ->> 'toBeDetached')::boolean as "To Be Detached",
      (disk ->> 'writeAcceleratorEnabled')::boolean as "Write Accelerator Enabled",
      lower(disk -> 'managedDisk' ->> 'id') as "Managed Disk ID"
    from
      azure_compute_virtual_machine,
      jsonb_array_elements(data_disks) as disk
    where
      lower(id) = $1;
  EOQ
}

query "compute_virtual_machine_network_interfaces" {
  sql = <<-EOQ
    with vm_interface as (
      select
        vm.public_ips as public_ips,
        vm.private_ips as private_ips,
        n ->> 'id' as network_id
      from
        azure_compute_virtual_machine as vm,
        jsonb_array_elements(network_interfaces) as n
      where
        lower(id) = $1
    )
    select
      i.name as "Name",
      i.provisioning_state as "Provisioning State",
      vi.public_ips as "Public IPs",
      vi.private_ips as "Private IPs",
      (ip_config -> 'properties' ->> 'primary')::boolean as "Primary IP Config",
      ip_config -> 'properties' ->> 'privateIPAddressVersion' as "Private IP Version",
      lower(i.id) as "Network Interface ID"
    from
      vm_interface vi
      left join azure_network_interface as i on lower(i.id) = lower(vi.network_id)
      left join jsonb_array_elements(i.ip_configurations) as ip_config on true;
  EOQ
}

query "compute_virtual_machine_guest_configuration_assignments" {
  sql = <<-EOQ
    select
      g ->> 'name' as "Name",
      g ->> 'complianceStatus' as "Compliance Status",
      g -> 'guestConfiguration' -> 'configurationSetting' ->> 'allowModuleOverwrite' as "Allow Module Overwrite",
      g -> 'guestConfiguration' -> 'configurationSetting' ->> 'configurationMode' as "Configuration Mode",
      g -> 'guestConfiguration' -> 'configurationSetting' ->> 'configurationModeFrequencyMins' as "Configuration Mode Frequency Mins",
      (g -> 'guestConfiguration' -> 'configurationSetting' ->> 'rebootIfNeeded')::boolean as "Reboot if Needed",
      g -> 'guestConfiguration' -> 'configurationSetting' ->> 'refreshFrequencyMins' as "Refresh Frequency Mins",
      g -> 'guestConfiguration' ->> 'version' as "Version"
    from
      azure_compute_virtual_machine,
      jsonb_array_elements(guest_configuration_assignments) as g
    where
      lower(id) = $1;
  EOQ
}
