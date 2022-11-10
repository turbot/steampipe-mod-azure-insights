dashboard "azure_compute_virtual_machine_scale_set_vm_detail" {

  title         = "Azure Compute Virtual Machine Scale Set VM Detail"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_scale_set_vm_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "scale_set_vm_id" {
    title = "Select a virtual machine scale set vm:"
    query = query.azure_compute_virtual_machine_scale_set_vm_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_compute_virtual_machine_scale_set_scale_set_name
      args = {
        id = self.input.scale_set_vm_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_scale_set_sku_name
      args = {
        id = self.input.scale_set_vm_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_compute_virtual_machine_scale_set_vm_node,
        node.azure_compute_virtual_machine_scale_set_vm_to_network_interface_node,
        node.azure_compute_virtual_machine_scale_set_vm_network_interface_to_network_security_group_node,
        node.azure_compute_virtual_machine_scale_set_vm_network_interface_to_subnet_node,
        node.azure_compute_virtual_machine_scale_set_vm_network_interface_subnet_to_virtual_network_node,
        node.azure_compute_virtual_machine_scale_set_vm_to_compute_disk_node,
        node.azure_compute_virtual_machine_scale_set_vm_from_vm_scale_set_node
      ]

      edges = [
        edge.azure_compute_virtual_machine_scale_set_vm_to_network_interface_edge,
        edge.azure_compute_virtual_machine_scale_set_vm_network_interface_to_network_security_group_edge,
        edge.azure_compute_virtual_machine_scale_set_vm_network_interface_to_subnet_edge,
        edge.azure_compute_virtual_machine_scale_set_vm_network_interface_subnet_to_virtual_network_edge,
        edge.azure_compute_virtual_machine_scale_set_vm_to_compute_disk_edge,
        edge.azure_compute_virtual_machine_scale_set_vm_from_vm_scale_set_edge

      ]

      args = {
        id = self.input.scale_set_vm_id.value
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
        query = query.azure_compute_virtual_machine_scale_set_vm_overview
        args = {
          id = self.input.scale_set_vm_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_compute_virtual_machine_scale_set_vm_tags
        args = {
          id = self.input.scale_set_vm_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Image Reference"
        query = query.azure_compute_virtual_machine_scale_set_vm_image_reference
        args = {
          id = self.input.scale_set_vm_id.value
        }
      }

      table {
        title = "OS Disks"
        query = query.azure_compute_virtual_machine_scale_set_vm_os_disks
        args = {
          id = self.input.scale_set_vm_id.value
        }
      }

      table {
        title = "Data Disks"
        query = query.azure_compute_virtual_machine_scale_set_vm_data_disks
        args = {
          id = self.input.scale_set_vm_id.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interface"
      query = query.azure_compute_virtual_machine_scale_set_vm_network_interface
      args = {
        id = self.input.scale_set_vm_id.value
      }
    }

  }

}

query "azure_compute_virtual_machine_scale_set_vm_input" {
  sql = <<-EOQ
    select
      vm.title as label,
      vm.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', vm.resource_group,
        'region', vm.region
      ) as tags
    from
      azure_compute_virtual_machine_scale_set_vm as vm,
      azure_subscription as s
    where
      vm.subscription_id = s.subscription_id
    order by
      vm.title;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_scale_set_name" {
  sql = <<-EOQ
    select
      'Scale Set Name' as label,
      scale_set_name as value
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_compute_virtual_machine_scale_set_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_compute_virtual_machine_scale_set_vm_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      instance_id as "Instance ID",
      type as "Type",
      provisioning_state as "Provisioning State",
      model_definition_applied as "Model Definition Applied",
      vm_id as "VM ID",
      region as "Region",
      resource_group as "Resource Group",
      id as "ID"
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_vm_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_compute_virtual_machine_scale_set_vm,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_vm_image_reference" {
  sql = <<-EOQ
    select
      virtual_machine_storage_profile -> 'imageReference' ->> 'offer' as "Offer",
      virtual_machine_storage_profile -> 'imageReference' ->> 'publisher' as "Publisher",
      virtual_machine_storage_profile -> 'imageReference' ->> 'sku' as "SKU",
      virtual_machine_storage_profile -> 'imageReference' ->> 'version' as "Version"
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_vm_os_disks" {
  sql = <<-EOQ
    select
      virtual_machine_storage_profile -> 'osDisk' ->> 'caching' as "Caching",
      virtual_machine_storage_profile -> 'osDisk' ->> 'createOption' as "Create Option",
      virtual_machine_storage_profile -> 'osDisk' ->> 'diskSizeGB' as "Disk Size (GB)",
      virtual_machine_storage_profile -> 'osDisk' -> 'managedDisk' ->> 'storageAccountType' as "Storage Account Type",
      virtual_machine_storage_profile -> 'osDisk' ->> 'osType' as "OS Type"
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_vm_data_disks" {
  sql = <<-EOQ
    select
      disk ->> 'caching' as "Caching",
      disk ->> 'createOption' as "Create Option",
      disk ->> 'diskSizeGB' as "Disk Size (GB)",
      disk ->> 'lun' as "Logical Unit Number",
      disk -> 'managedDisk' ->> 'storageAccountType' as "Storage Account Type",
      (disk -> 'writeAcceleratorEnabled')::boolean as "Write Accelerator Enabled"
    from
      azure_compute_virtual_machine_scale_set_vm,
      jsonb_array_elements(virtual_machine_storage_profile -> 'dataDisks') as disk
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_vm_network_interface" {
  sql = <<-EOQ
    select
      nic ->> 'name' as "Name",
      (nic -> 'properties' ->> 'enableAcceleratedNetworking')::boolean as "Enable Accelerated Networking",
      (nic -> 'properties' ->> 'enableIPForwarding')::boolean as "Enable IP Forwarding",
      (nic -> 'properties' ->> 'primary')::boolean as "Primary",
      ip ->> 'name' as "IP Config Name",
      (ip -> 'properties' ->> 'primary')::boolean as "IP Primary",
      ip -> 'properties' ->> 'privateIPAddressVersion' as "Private IP Address Version"
    from
      azure_compute_virtual_machine_scale_set_vm,
      jsonb_array_elements(virtual_machine_network_profile_configuration -> 'networkInterfaceConfigurations') nic,
      jsonb_array_elements(nic -> 'properties' -> 'ipConfigurations') ip
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_vm_node" {
  category = category.azure_compute_virtual_machine_scale_set_vm

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'VM ID', vm_id,
        'SKU Name', sku_name,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Provisioning State', provisioning_state,
        'Region', region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_vm_to_network_interface_node" {
  category = category.azure_compute_virtual_machine_scale_set_network_interface

  sql = <<-EOQ
    select
      lower(nic.id) as id,
      nic.title as title,
      jsonb_build_object(
        'Name', nic.name,
        'ID', nic.id,
        'Primary', nic.primary,
        'Provisioning State', nic.provisioning_state,
        'Enable Accelerated Networking', nic.enable_accelerated_networking,
        'Subscription ID', nic.subscription_id,
        'Resource Group', nic.resource_group,
        'Provisioning State', nic.provisioning_state,
        'Region', nic.region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_vm_to_network_interface_edge" {
  title = "network interface"

  sql = <<-EOQ
    select
      lower(vm.id) as from_id,
      lower(nic.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_vm_network_interface_to_network_security_group_node" {
  category = category.azure_network_security_group

  sql = <<-EOQ
    select
      lower(nsg.id) as id,
      nsg.title as title,
      jsonb_build_object(
        'Name', nsg.name,
        'ID', nsg.id,
        'Subscription ID', nsg.subscription_id,
        'Resource Group', nsg.resource_group,
        'Region', nsg.region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
      left join azure_network_security_group as nsg on lower(nsg.id) = lower(nic.network_security_group ->> 'id')
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_vm_network_interface_to_network_security_group_edge" {
  title = "nsg"

  sql = <<-EOQ
    select
      lower(nic.id) as from_id,
      lower(nsg.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
      left join azure_network_security_group as nsg on lower(nsg.id) = lower(nic.network_security_group ->> 'id')
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_vm_network_interface_to_subnet_node" {
  category = category.azure_subnet

  sql = <<-EOQ
    with ip_configs as (
      select
        nic.ip_configurations as ip_config,
        lower(vm.id) as vm_id,
        lower(nic.id) as nic_id
      from
        azure_compute_virtual_machine_scale_set_vm as vm
        left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
      where
        lower(vm.id) = lower($1)
    )
    select
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group
      ) as properties
    from
      ip_configs,
      jsonb_array_elements(ip_config) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_vm_network_interface_to_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    with ip_configs as (
      select
        nic.ip_configurations as ip_config,
        lower(vm.id) as vm_id,
        lower(nic.id) as nic_id
      from
        azure_compute_virtual_machine_scale_set_vm as vm
        left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
      where
        lower(vm.id) = lower($1)
    )
    select
      lower(config.nic_id) as from_id,
      lower(s.id) as to_id
    from
      ip_configs as config,
      jsonb_array_elements(ip_config) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id');
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_vm_network_interface_subnet_to_virtual_network_node" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    with ip_configs as (
      select
        nic.ip_configurations as ip_config,
        lower(vm.id) as vm_id,
        lower(nic.id) as nic_id
      from
        azure_compute_virtual_machine_scale_set_vm as vm
        left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
      where
        vm.id = $1
    ), subnet_list as (
      select
        lower(c -> 'properties' -> 'subnet' ->> 'id') as subnet_id
      from
        ip_configs,
        jsonb_array_elements(ip_config) as c
    )
    select
      lower(vn.id) as id,
      vn.title as title,
      jsonb_build_object(
        'Name', vn.name,
        'ID', vn.id,
        'Region', region,
        'Subscription ID', vn.subscription_id,
        'Resource Group', vn.resource_group
      ) as properties
    from
      azure_virtual_network as vn,
      jsonb_array_elements(vn.subnets) as s
    where
      lower(s ->> 'id') in (select subnet_id from subnet_list)
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_vm_network_interface_subnet_to_virtual_network_edge" {
  title = "virtual network"

  sql = <<-EOQ
    with ip_configs as (
      select
        nic.ip_configurations as ip_config,
        lower(vm.id) as vm_id,
        lower(nic.id) as nic_id
      from
        azure_compute_virtual_machine_scale_set_vm as vm
        left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
      where
        vm.id = $1
    ), subnet_list as (
      select
        lower(c -> 'properties' -> 'subnet' ->> 'id') as subnet_id
      from
        ip_configs,
        jsonb_array_elements(ip_config) as c
    )
    select
      lower(s ->> 'id') as from_id,
      lower(vn.id) as to_id
    from
      azure_virtual_network as vn,
      jsonb_array_elements(vn.subnets) as s
    where
      lower(s ->> 'id') in (select subnet_id from subnet_list)
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_vm_to_compute_disk_node" {
  category = category.azure_compute_disk

  sql = <<-EOQ
    select
      d.id as id,
      d.title as title,
      jsonb_build_object(
        'Name', d.name,
        'ID', d.id,
        'Disk Size (GB)', d.disk_size_gb,
        'Encryption Type', d.encryption_type,
        'Type', d.Type,
        'SKU Name', d.sku_name,
        'Subscription ID', d.subscription_id,
        'Resource Group', d.resource_group,
        'Provisioning State', d.provisioning_state,
        'Region', d.region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_vm as vm,
      jsonb_array_elements(virtual_machine_storage_profile -> 'dataDisks') as disk
      left join azure_compute_disk as d on lower(d.id) = lower(disk -> 'managedDisk' ->> 'id')
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_vm_to_compute_disk_edge" {
  title = "data disk"

  sql = <<-EOQ
    select
      vm.id as from_id,
      d.id as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm,
      jsonb_array_elements(virtual_machine_storage_profile -> 'dataDisks') as disk
      left join azure_compute_disk as d on lower(d.id) = lower(disk -> 'managedDisk' ->> 'id')
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_vm_from_vm_scale_set_node" {
  category = category.azure_compute_virtual_machine_scale_set

  sql = <<-EOQ
    select
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Type', s.type,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group,
        'Provisioning State', s.provisioning_state,
        'Region', s.region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name
    where
      vm.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_vm_from_vm_scale_set_edge" {
  title = "scale set"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(vm.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name
    where
      vm.id = $1;
  EOQ

  param "id" {}
}