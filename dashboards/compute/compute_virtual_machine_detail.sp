dashboard "azure_compute_virtual_machine_detail" {

  title         = "Azure Compute Virtual Machine Detail"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "vm_id" {
    title = "Select a virtual machine:"
    query = query.azure_compute_virtual_machine_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_compute_virtual_machine_status
      args = {
        id = self.input.vm_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_encryption_status
      args = {
        id = self.input.vm_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_disaster_recovery_status
      args = {
        id = self.input.vm_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_ingress_access
      args = {
        id = self.input.vm_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_vulnerability_assessment_solution
      args = {
        id = self.input.vm_id.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "network_interfaces" {
        sql = <<-EOQ
          with network_interface_id as (
            select
              id as vm_id,
              jsonb_array_elements(network_interfaces)->>'id' as n_id
            from
              azure_compute_virtual_machine
          )
          select
            lower(vn.n_id) as network_interface_id
          from
            network_interface_id as vn
            left join azure_network_interface as n on lower(vn.n_id) = lower(n.id)
          where
            lower(vn.vm_id) = $1;
          EOQ

        args = [self.input.vm_id.value]
      }

      nodes = [
        node.compute_virtual_machine,
        node.azure_compute_virtual_machine_to_data_disk_node,
        node.azure_compute_virtual_machine_to_os_disk_node,
        node.network_network_interface,
        node.azure_compute_virtual_machine_network_interface_to_public_ip_node,
        node.azure_compute_virtual_machine_to_image_node,
        node.azure_compute_virtual_machine_network_interface_to_network_security_group_node,
        node.azure_compute_virtual_machine_to_subnet_node,
        node.azure_compute_virtual_machine_network_interface_subnet_to_virtual_network_node,
        node.azure_compute_virtual_machine_from_lb_backend_address_pool_node,
        node.azure_compute_virtual_machine_from_lb_node,
        node.azure_compute_virtual_machine_from_application_gateway_backend_address_pool_node,
        node.azure_compute_virtual_machine_from_application_gateway_node
      ]

      edges = [
        edge.azure_compute_virtual_machine_to_data_disk_edge,
        edge.azure_compute_virtual_machine_to_os_disk_edge,
        edge.compute_virtual_machine_to_network_network_interface,
        edge.azure_compute_virtual_machine_network_interface_to_public_ip_edge,
        edge.azure_compute_virtual_machine_to_image_edge,
        edge.azure_compute_virtual_machine_network_interface_to_network_security_group_edge,
        edge.azure_compute_virtual_machine_to_subnet_edge,
        edge.azure_compute_virtual_machine_network_interface_subnet_to_virtual_network_edge,
        edge.azure_compute_virtual_machine_from_lb_backend_address_pool_edge,
        edge.azure_compute_virtual_machine_from_lb_edge,
        edge.azure_compute_virtual_machine_from_application_gateway_backend_address_pool_edge,
        edge.azure_compute_virtual_machine_from_application_gateway_edge
      ]

      args = {
        compute_virtual_machine_ids = [self.input.vm_id.value]
        network_interface_ids       = with.network_interfaces.rows[*].network_interface_id
        id                          = self.input.vm_id.value
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
        query = query.azure_compute_virtual_machine_overview
        args = {
          id = self.input.vm_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_compute_virtual_machine_tags
        args = {
          id = self.input.vm_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Storage Profile"
        query = query.azure_compute_virtual_machine_storage_profile
        args = {
          id = self.input.vm_id.value
        }

        column "Disk Name" {
          href = "/azure_insights.dashboard.azure_compute_disk_detail?input.disk_id={{ .ID | @uri }}"
        }
      }

      table {
        title = "Image"
        query = query.azure_compute_virtual_machine_image
        args = {
          id = self.input.vm_id.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Security Groups"
      query = query.azure_compute_virtual_machine_security_groups
      args = {
        id = self.input.vm_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.azure_compute_virtual_machine_network_interfaces
      args = {
        id = self.input.vm_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Guest Configuration"
      query = query.azure_compute_virtual_machine_guest_configuration_assignments
      args = {
        id = self.input.vm_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Data Disks"
      query = query.azure_compute_virtual_machine_data_disks
      args = {
        id = self.input.vm_id.value
      }
    }

  }

}

query "azure_compute_virtual_machine_input" {
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

query "azure_compute_virtual_machine_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(power_state) as value
    from
      azure_compute_virtual_machine
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_compute_virtual_machine_encryption_status" {
  sql = <<-EOQ
    select
      'Host Encryption' as label,
      case when security_profile -> 'encryptionAtHost' <> 'true' or security_profile -> 'encryptionAtHost' is null then 'Disabled' else 'Enabled' end as value,
      case when security_profile -> 'encryptionAtHost' <> 'true' or security_profile -> 'encryptionAtHost' is null then 'alert' else 'ok' end as type
    from
      azure_compute_virtual_machine
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_disaster_recovery_status" {
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
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_ingress_access" {
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
      id = $1;

  EOQ

  param "id" {}
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
      id = $1;

  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_vulnerability_assessment_solution" {
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
      id = $1;
  EOQ

  param "id" {}
}

node "compute_virtual_machine" {
  category = category.azure_compute_virtual_machine

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', vm_id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Power State', power_state,
        'OS Type', os_type,
        'Type', type,
        'Region', region
      ) as properties
    from
      azure_compute_virtual_machine
    where
      lower(id) = any($1);
  EOQ

  param "compute_virtual_machine_ids" {}
}

node "azure_compute_virtual_machine_to_data_disk_node" {
  category = category.azure_compute_disk

  sql = <<-EOQ
    with vm_disk_id as (
      select
        id,
        jsonb_array_elements(data_disks)->'managedDisk'->>'id' as d_id
      from
        azure_compute_virtual_machine
    )
    select
      lower(d.id) as id,
      d.title as title,
      jsonb_build_object(
        'Name', d.name,
        'ID', d.id,
        'Disk Size GB', d.disk_size_gb,
        'Encryption Type' , d.encryption_type,
        'SKU Name', d.sku_name,
        'Type', d.type,
        'Subscription ID', d.subscription_id,
        'Resource Group', d.resource_group,
        'Region', d.region
      ) as properties
    from
      azure_compute_disk as d
      left join vm_disk_id as v on lower(d.id) = lower(v.d_id)
    where
      v.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_data_disk_edge" {
  title = "data disk"

  sql = <<-EOQ
    with vm_disk_id as (
      select
        id,
        jsonb_array_elements(data_disks)->'managedDisk'->>'id' as d_id
      from
        azure_compute_virtual_machine
    )
    select
      lower(v.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_disk as d
      left join vm_disk_id as v on lower(d.id) = lower(v.d_id)
    where
      v.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_to_os_disk_node" {
  category = category.azure_compute_disk

  sql = <<-EOQ
    select
      lower(d.id) as id,
      d.title as title,
      jsonb_build_object(
        'Name', d.name,
        'ID', d.id,
        'Disk Size GB', d.disk_size_gb,
        'Encryption Type' , d.encryption_type,
        'SKU Name', d.sku_name,
        'Type', d.type,
        'Subscription ID', d.subscription_id,
        'Resource Group', d.resource_group,
        'Region', d.region
      ) as properties
    from
      azure_compute_virtual_machine as vm
      left join azure_compute_disk as d on lower(d.managed_by) = lower(vm.id)
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_os_disk_edge" {
  title = "os disk"

  sql = <<-EOQ
    select
      lower(vm.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_virtual_machine as vm
      left join azure_compute_disk as d on lower(d.managed_by) = lower(vm.id)
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_to_network_interface_node" {
  category = category.azure_network_interface

  sql = <<-EOQ
    with network_interface_id as (
      select
        id as vm_id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    )
    select
      lower(vn.n_id) as id,
      n.title as title,
      jsonb_build_object(
        'Name', n.name,
        'ID', n.id,
        'Type', n.type,
        'Subscription ID', n.subscription_id,
        'Resource Group', n.resource_group,
        'Region', n.region
      ) as properties
    from
      network_interface_id as vn
      left join azure_network_interface as n on lower(vn.n_id) = lower(n.id)
    where
      vn.vm_id = $1;
  EOQ

  param "id" {}
}

edge "compute_virtual_machine_to_network_network_interface" {
  title = "network interface"

  sql = <<-EOQ
    select
      virtual_machine_id as from_id,
      network_interface_id as to_id
    from
      unnest($1::text[]) as virtual_machine_id,
      unnest($2::text[]) as network_interface_id
  EOQ

  param "compute_virtual_machine_ids" {}
  param "network_interface_ids" {}
}

node "azure_compute_virtual_machine_network_interface_to_network_security_group_node" {
  category = category.azure_network_security_group

  sql = <<-EOQ
    with network_interface_id as (
      select
        id as vm_id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
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
      network_interface_id as vn
      left join azure_network_interface as n on vn.n_id = n.id
      left join azure_network_security_group as s on n.network_security_group_id = s.id
    where
      vn.vm_id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_network_interface_to_network_security_group_edge" {
  title = "nsg"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    )
    select
      lower(s.id) as to_id,
      lower(n.id) as from_id
    from
      network_interface_id as vn
      left join azure_network_interface as n on vn.n_id = n.id
      left join azure_network_security_group as s on n.network_security_group_id = s.id
    where
      vn.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_to_subnet_node" {
  category = category.azure_subnet

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        id = $1
    )
    select
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Address Prefix', s.address_prefix,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group
      ) as properties
    from
      azure_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
    where
      nic.id in (select nic_id from network_interface_id);
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        id = $1
    )
    select
      coalesce(
        lower(nic.network_security_group_id),
        lower(nic.id)
      ) as from_id,
      lower(s.id) as to_id
    from
      azure_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
    where
      nic.id in (select nic_id from network_interface_id);
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_network_interface_subnet_to_virtual_network_node" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        id = $1
    ), subnet_id as (
        select
          s.id as id,
          s.virtual_network_name
        from
          azure_network_interface as nic,
          jsonb_array_elements(ip_configurations) as c
          left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
        where
          nic.id in (select nic_id from network_interface_id)
    )
    select
      lower(vn.id) as id,
      vn.title as title,
      jsonb_build_object(
        'Name', vn.name,
        'ID', vn.id,
        'Subscription ID', vn.subscription_id,
        'Resource Group', vn.resource_group
      ) as properties
    from
      azure_virtual_network as vn,
      jsonb_array_elements(subnets) as s
      left join subnet_id as sub on lower(sub.id) = lower(s ->> 'id')
    where
      s ->> 'id' in (select id from subnet_id);
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_network_interface_subnet_to_virtual_network_edge" {
  title = "virtual network"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        id = $1
    ), subnet_id as (
        select
          s.id as id,
          s.virtual_network_name
        from
          azure_network_interface as nic,
          jsonb_array_elements(ip_configurations) as c
          left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
        where
          nic.id in (select nic_id from network_interface_id)
    )
    select
      lower(vn.id) as to_id,
      lower(sub.id) as from_id
    from
      azure_virtual_network as vn,
      jsonb_array_elements(subnets) as s
      left join subnet_id as sub on lower(sub.id) = lower(s ->> 'id')
    where
      s ->> 'id' in (select id from subnet_id);
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_network_interface_to_public_ip_node" {
  category = category.azure_public_ip

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
        lower(vm.id) = lower($1)
    ),
     ip_address as (
      select
        id,
        jsonb_array_elements_text(public_ips) as ip
      from
        azure_compute_virtual_machine
      where
        lower(id) = lower($1)
    )
    select
      lower(p.id) as id,
      p.title as title,
      jsonb_build_object(
        'Name', p.name,
        'ID', p.id,
        'IP Address', p.ip_address,
        'Subscription ID', p.subscription_id,
        'Resource Group', p.resource_group,
        'Region', p.region
      ) as properties
    from
      network_interfaces as n,
      jsonb_array_elements(ip_configuration) as ip_config
      left join azure_public_ip as p on lower(p.id) = lower(ip_config -> 'properties' -> 'publicIPAddress' ->> 'id');
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_network_interface_to_public_ip_edge" {
  title = "public ip"

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
        lower(vm.id) = lower($1)
    ),
     ip_address as (
      select
        id,
        jsonb_array_elements_text(public_ips) as ip
      from
        azure_compute_virtual_machine
      where
        lower(id) = lower($1)
    )
    select
      lower(n.nic_id) as from_id,
      lower(p.id) as to_id
    from
      network_interfaces as n,
      jsonb_array_elements(ip_configuration) as ip_config
      left join azure_public_ip as p on lower(p.id) = lower(ip_config -> 'properties' -> 'publicIPAddress' ->> 'id');
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_to_image_node" {
  category = category.azure_compute_image

  sql = <<-EOQ
    select
      lower(i.id) as id,
      i.title as title,
      jsonb_build_object(
        'Name', i.name,
        'ID', i.id,
        'Subscription ID', i.subscription_id,
        'Resource Group', i.resource_group,
        'Region', i.region
      ) as properties
    from
      azure_compute_image as i
      left join azure_compute_virtual_machine as v on lower(i.id) = lower(v.image_id)
    where
      v.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_image_edge" {
  title = "uses"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(i.id) as to_id
    from
      azure_compute_image as i
      left join azure_compute_virtual_machine as v on lower(i.id) = lower(v.image_id)
    where
      v.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_from_lb_backend_address_pool_node" {
  category = category.azure_lb_backend_address_pool

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
        vm.id = $1
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
      lower(pool.id) as id,
      pool.title as title,
      jsonb_build_object(
        'Name', pool.name,
        'ID', pool.id,
        'Type', pool.type,
        'Subscription ID', pool.subscription_id,
        'Resource Group', pool.resource_group
      ) as properties
    from
      loadBalancerBackendAddressPools as p
      left join azure_lb_backend_address_pool as pool on lower(pool.id) = lower(p.id);
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_from_lb_backend_address_pool_edge" {
  title = "virtual machine"

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
        vm.id = $1
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
      lower(p.id) as from_id,
      lower($1) as to_id
    from
      loadBalancerBackendAddressPools as p
      left join azure_lb_backend_address_pool as pool on lower(pool.id) = lower(p.id);
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_from_lb_node" {
  category = category.azure_lb

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
        vm.id = $1
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
      lower(lb.id) as id,
      lb.title as title,
      jsonb_build_object(
        'Name', lb.name,
        'ID', lb.id,
        'SKU Name', lb.sku_name,
        'Region', lb.region,
        'Subscription ID', lb.subscription_id,
        'Resource Group', lb.resource_group
      ) as properties
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as pool
    where
      lower(pool ->> 'id') in (select lower(id) from loadBalancerBackendAddressPools);
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_from_lb_edge" {
  title = "lb backend address pool"

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
        vm.id = $1
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
      lower(lb.id) as from_id,
      lower(pool ->> 'id') as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as pool
    where
      lower(pool ->> 'id') in (select lower(id) from loadBalancerBackendAddressPools);
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_from_application_gateway_backend_address_pool_node" {
  category = category.azure_lb_backend_address_pool

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
        vm.id = $1
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
      lower(p ->> 'id') as id,
      p ->> 'name' as title,
      jsonb_build_object(
        'Name', p ->> 'name',
        'ID', p ->> 'id',
        'Type', p ->> 'type',
        'provisioning_state', p ->> 'provisioning_state',
        'Subscription ID', g.subscription_id,
        'Resource Group', g.resource_group
      ) as properties
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
    where
      lower(p ->> 'id') in (select lower(id) from vm_application_gateway_backend_address_pool);
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_from_application_gateway_backend_address_pool_edge" {
  title = "virtual machine"

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
        vm.id = $1
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
      lower(p ->> 'id') as from_id,
      lower($1) as to_id
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
    where
      lower(p ->> 'id') in (select lower(id) from vm_application_gateway_backend_address_pool);
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_from_application_gateway_node" {
  category = category.azure_application_gateway

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
        vm.id = $1
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
      lower(g.id) as id,
      g.name as title,
      jsonb_build_object(
        'Name', g.name ,
        'ID', g.id,
        'SKU', g.sku,
        'Type', g.type,
        'Operational State', g.operational_state,
        'Subscription ID', g.subscription_id,
        'Resource Group', g.resource_group
      ) as properties
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
    where
      lower(p ->> 'id') in (select lower(id) from vm_application_gateway_backend_address_pool);
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_from_application_gateway_edge" {
  title = "lb backend address pool"

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
        vm.id = $1
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
      lower(g.id) as from_id,
      lower(p ->> 'id') as to_id
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
    where
      lower(p ->> 'id') in (select lower(id) from vm_application_gateway_backend_address_pool);
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_overview" {
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
      id = $1
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_compute_virtual_machine,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_storage_profile" {
  sql = <<-EOQ
    select
      os_disk_name as "Disk Name",
      os_disk_caching as "Disk Caching",
      os_disk_create_option as "Disk Create Option",
      os_disk_vhd_uri as "Virtual Hard Disk URI",
      d.id as "ID"
    from
      azure_compute_virtual_machine as vm
      left join azure_compute_disk as d on  vm.os_disk_name = d.name  and lower(vm.id)= lower(d.managed_by)
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_image" {
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
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_security_groups" {
  sql = <<-EOQ
    select
      nsg.name as "Name",
      nsg.provisioning_state as "Provisioning State",
      nsg.region as "Region",
      nsg.resource_group as "Resource Group",
      nsg.id as "Security Group ID"
    from
      azure_network_security_group as nsg
      left join azure_compute_virtual_machine as vm on vm.network_interfaces @> nsg.network_interfaces
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_data_disks" {
  sql = <<-EOQ
    select
      disk ->> 'name' as "Name",
      disk ->> 'caching' as "Caching",
      disk ->> 'createOption' as "Create Option",
      (disk ->> 'toBeDetached')::boolean as "To Be Detached",
      (disk ->> 'writeAcceleratorEnabled')::boolean as "Write Accelerator Enabled",
      disk -> 'managedDisk' ->> 'id' as "Managed Disk ID"
    from
      azure_compute_virtual_machine,
      jsonb_array_elements(data_disks) as disk
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_network_interfaces" {
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
        id = $1
    )
    select
      i.name as "Name",
      i.provisioning_state as "Provisioning State",
      vi.public_ips as "Public IPs",
      vi.private_ips as "Private IPs",
      (ip_config -> 'properties' ->> 'primary')::boolean as "Primary IP Config",
      ip_config -> 'properties' ->> 'privateIPAddressVersion' as "Private IP Version",
      i.id as "Network Interface ID"
    from
      vm_interface vi
      left join azure_network_interface as i on lower(i.id) = lower(vi.network_id)
      left join jsonb_array_elements(i.ip_configurations) as ip_config on true;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_guest_configuration_assignments" {
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
      id = $1;
  EOQ

  param "id" {}
}
