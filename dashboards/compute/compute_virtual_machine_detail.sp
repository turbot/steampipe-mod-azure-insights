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

      nodes = [
        node.azure_compute_virtual_machine_node,
        node.azure_compute_virtual_machine_to_managed_disk_node,
        node.azure_compute_virtual_machine_to_network_interface_node,
        node.azure_compute_virtual_machine_to_public_ip_node,
        node.azure_compute_virtual_machine_to_image_node,
        node.azure_compute_virtual_machine_network_interface_to_network_security_group_node
      ]

      edges = [
        edge.azure_compute_virtual_machine_to_managed_disk_edge,
        edge.azure_compute_virtual_machine_to_network_interface_edge,
        edge.azure_compute_virtual_machine_to_public_ip_edge,
        edge.azure_compute_virtual_machine_to_image_edge,
        edge.azure_compute_virtual_machine_network_interface_to_network_security_group_edge
      ]

      args = {
        id = self.input.vm_id.value
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
      v.id as value,
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
      power_state as value
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
        left join azure_compute_virtual_machine as w on w.vm_id = a.vm_id,
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
      left join agent_installed_vm as b on a.vm_id = b.vm_id
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_node" {
  category = category.azure_compute_virtual_machine

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'VM ID', vm_id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Provisioning State', provisioning_state,
        'OS Type', os_type,
        'Region', region
      ) as properties
    from
      azure_compute_virtual_machine
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_to_managed_disk_node" {
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
      left join vm_disk_id as v on d.id = v.d_id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_managed_disk_edge" {
  title = "manage disk"

  sql = <<-EOQ
    with vm_disk_id as (
      select
        id,
        jsonb_array_elements(data_disks)->'managedDisk'->>'id' as d_id
      from
        azure_compute_virtual_machine
    )
    select
      v.id as from_id,
      d.id as to_id
    from
      azure_compute_disk as d
      left join vm_disk_id as v on d.id = v.d_id
    where
      v.id = $1;
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
      vn.n_id as id,
      n.title as title,
      n.id as network_id,
      jsonb_build_object(
        'Name', n.name,
        'ID', n.id,
        'Subscription ID', n.subscription_id,
        'Resource Group', n.resource_group,
        'Region', n.region
      ) as properties
    from
      network_interface_id as vn
      left join azure_network_interface as n on vn.n_id = n.id
    where
      vn.vm_id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_network_interface_edge" {
  title = "network interface"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    )
    select
      n.id as to_id,
      vn.id as from_id
    from
      network_interface_id as vn
      left join azure_network_interface as n on vn.n_id = n.id
    where
      vn.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_to_public_ip_node" {
  category = category.azure_public_ip

  sql = <<-EOQ
    with ip_address as (
      select
        id,
        jsonb_array_elements_text(public_ips) as ip
      from
        azure_compute_virtual_machine
    )
    select
      a.id as id,
      a.title as title,
      a.id as public_ip,
      jsonb_build_object(
        'Name', a.name,
        'ID', a.id,
        'Subscription ID', a.subscription_id,
        'Resource Group', a.resource_group,
        'Region', a.region
      ) as properties
    from
      ip_address as p
      left join azure_public_ip as a on (p.ip)::inet = a.ip_address
    where
      p.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_public_ip_edge" {
  title = "public ip"

  sql = <<-EOQ
    with ip_address as (
      select
        id,
        jsonb_array_elements_text(public_ips) as ip
      from
        azure_compute_virtual_machine
    )
    select
      a.id as to_id,
      p.id as from_id
    from
      ip_address as p
      left join azure_public_ip as a on (p.ip)::inet = a.ip_address
    where
      p.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_to_image_node" {
  category = category.azure_image

  sql = <<-EOQ
    select
      v.id,
      i.id as id,
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
      left join azure_compute_virtual_machine as v on i.id = v.image_id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_to_image_edge" {
  title = "uses"

  sql = <<-EOQ
    select
      v.id as from_id,
      i.id as to_id
    from
      azure_compute_image as i
      left join azure_compute_virtual_machine as v on i.id = v.image_id
    where
      v.id = $1;
  EOQ

  param "id" {}
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
      network_interface_id as vn
      left join azure_network_interface as n on vn.n_id = n.id
      left join azure_network_security_group as s on n.network_security_group_id = s.id
    where
      vn.vm_id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_network_interface_to_network_security_group_edge" {
  title = "NSG"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    )
    select
      s.id as to_id,
      n.id as from_id
    from
      network_interface_id as vn
      left join azure_network_interface as n on vn.n_id = n.id
      left join azure_network_security_group as s on n.network_security_group_id = s.id
    where
      vn.id = $1;
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
      os_disk_vhd_uri as "Virtual Hard Disk URI"
    from
      azure_compute_virtual_machine
    where
      id = $1;
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
      left join azure_network_interface as i on i.id = vi.network_id
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
