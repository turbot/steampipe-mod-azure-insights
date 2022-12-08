dashboard "compute_virtual_machine_scale_set_vm_detail" {

  title         = "Azure Compute Virtual Machine Scale Set VM Detail"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_scale_set_vm_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "scale_set_vm_id" {
    title = "Select a virtual machine scale set vm:"
    query = query.compute_virtual_machine_scale_set_vm_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.compute_virtual_machine_scale_set_scale_set_name
      args = {
        id = self.input.scale_set_vm_id.value
      }
    }

    card {
      width = 2
      query = query.compute_virtual_machine_scale_set_sku_name
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

      with "compute_disks" {
        sql = <<-EOQ
          select
            lower(d.id) as disk_id
          from
            azure_compute_virtual_machine_scale_set_vm as vm,
            jsonb_array_elements(virtual_machine_storage_profile -> 'dataDisks') as disk
            left join azure_compute_disk as d on lower(d.id) = lower(disk -> 'managedDisk' ->> 'id')
          where
            d.id is not null
            and lower(vm.id) = $1;
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      with "compute_virtual_machine_scale_set_network_interfaces" {
        sql = <<-EOQ
          select
            lower(nic.id) as network_interface_id
          from
            azure_compute_virtual_machine_scale_set_vm as vm
            left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
          where
            lower(vm.id) = $1;
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      with "compute_virtual_machine_scale_sets" {
        sql = <<-EOQ
          select
            lower(s.id) as scale_set_id
          from
            azure_compute_virtual_machine_scale_set_vm as vm
            left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name
          where
            lower(vm.id) = $1;
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      with "network_load_balancer_backend_address_pools" {
        sql = <<-EOQ
          with compute_virtual_machine_scale_set_network_interface as (
            select
              nic.id as nic_id,
              lower(c ->> 'id') as config_id
            from
              azure_compute_virtual_machine_scale_set_network_interface as nic,
              jsonb_array_elements(ip_configurations) as c
            where
              lower(nic.virtual_machine ->> 'id') = $1
          )
          select
            lower(p.id) as pool_id
          from
            azure_lb_backend_address_pool as p,
            jsonb_array_elements(backend_ip_configurations) as c
          where
            lower(c ->> 'id') in (select config_id from compute_virtual_machine_scale_set_network_interface)
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      with "network_load_balancers" {
        sql = <<-EOQ
          with compute_virtual_machine_scale_set_network_interface as (
            select
              nic.id as nic_id,
              c ->> 'id' as config_id
            from
              azure_compute_virtual_machine_scale_set_network_interface as nic,
              jsonb_array_elements(ip_configurations) as c
            where
              lower(nic.virtual_machine ->> 'id') = $1
          ),
          backend_address_pool as (
            select
              lower(p.id) as id
            from
              azure_lb_backend_address_pool as p,
              jsonb_array_elements(backend_ip_configurations) as c
            where
              c ->> 'id' in (select config_id from compute_virtual_machine_scale_set_network_interface)
          )
          select
            lower(lb.id) as lb_id
          from
            azure_lb as lb,
            jsonb_array_elements(backend_address_pools) as p
            left join backend_address_pool as pool on pool.id = lower(p ->> 'id')
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      with "network_security_groups" {
        sql = <<-EOQ
          select
            lower(nsg.id) as nsg_id
          from
            azure_compute_virtual_machine_scale_set_vm as vm
            left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
            left join azure_network_security_group as nsg on lower(nsg.id) = lower(nic.network_security_group ->> 'id')
          where
            lower(vm.id) = $1;
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      with "network_subnets" {
        sql = <<-EOQ
          with ip_configs as (
            select
              nic.ip_configurations as ip_config,
              lower(vm.id) as vm_id,
              lower(nic.id) as nic_i
            from
              azure_compute_virtual_machine_scale_set_vm as vm
              left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
            where
            lower(vm.id) = $1
          )
          select
            lower(s.id) as subnet_id
          from
            ip_configs,
            jsonb_array_elements(ip_config) as c
            left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      with "network_virtual_networks" {
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
              lower(vm.id) = $1
          ), subnet_list as (
            select
              lower(c -> 'properties' -> 'subnet' ->> 'id') as subnet_id
            from
              ip_configs,
              jsonb_array_elements(ip_config) as c
          )
          select
            lower(vn.id) as network_id
          from
            azure_virtual_network as vn,
            jsonb_array_elements(vn.subnets) as s
          where
            lower(s ->> 'id') in (select lower(subnet_id) from subnet_list)
        EOQ

        args = [self.input.scale_set_vm_id.value]
      }

      nodes = [
        node.compute_disk,
        node.compute_virtual_machine_scale_set_network_interface,
        node.compute_virtual_machine_scale_set_vm,
        node.compute_virtual_machine_scale_set,
        node.network_load_balancer_backend_address_pool,
        node.network_load_balancer,
        node.network_network_security_group,
        node.network_subnet,
        node.network_virtual_network,
      ]

      edges = [
        edge.compute_virtual_machine_scale_set_to_compute_virtual_machine_scale_set_vm,
        edge.compute_virtual_machine_scale_set_vm_to_compute_disk,
        edge.compute_virtual_machine_scale_set_vm_to_compute_virtual_machine_scale_set_network_interface,
        edge.compute_virtual_machine_scale_set_vm_to_network_load_balancer_backend_address_pool,
        edge.compute_virtual_machine_scale_set_vm_to_network_load_balancer,
        edge.compute_virtual_machine_scale_set_vm_to_network_security_group,
        edge.compute_virtual_machine_scale_set_vm_to_network_subnet,
        edge.network_subnet_to_network_virtual_network,
      ]

      args = {
        compute_disk_ids                                        = with.compute_disks.rows[*].disk_id
        compute_virtual_machine_scale_set_ids                   = with.compute_virtual_machine_scale_sets.rows[*].scale_set_id
        compute_virtual_machine_scale_set_network_interface_ids = with.compute_virtual_machine_scale_set_network_interfaces.rows[*].network_interface_id
        compute_virtual_machine_scale_set_vm_ids                = [self.input.scale_set_vm_id.value]
        network_load_balancer_backend_address_pool_ids          = with.network_load_balancer_backend_address_pools.rows[*].pool_id
        network_load_balancer_ids                               = with.network_load_balancers.rows[*].lb_id
        network_security_group_ids                              = with.network_security_groups.rows[*].nsg_id
        network_subnet_ids                                      = with.network_subnets.rows[*].subnet_id
        network_virtual_network_ids                             = with.network_virtual_networks.rows[*].network_id
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
        query = query.compute_virtual_machine_scale_set_vm_overview
        args = {
          id = self.input.scale_set_vm_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_virtual_machine_scale_set_vm_tags
        args = {
          id = self.input.scale_set_vm_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Image Reference"
        query = query.compute_virtual_machine_scale_set_vm_image_reference
        args = {
          id = self.input.scale_set_vm_id.value
        }
      }

      table {
        title = "OS Disks"
        query = query.compute_virtual_machine_scale_set_vm_os_disks
        args = {
          id = self.input.scale_set_vm_id.value
        }
      }

      table {
        title = "Data Disks"
        query = query.compute_virtual_machine_scale_set_vm_data_disks
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
      query = query.compute_virtual_machine_scale_set_vm_network_interface
      args = {
        id = self.input.scale_set_vm_id.value
      }
    }

  }

}

query "compute_virtual_machine_scale_set_vm_input" {
  sql = <<-EOQ
    select
      vm.title as label,
      lower(vm.id) as value,
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

query "compute_virtual_machine_scale_set_scale_set_name" {
  sql = <<-EOQ
    select
      'Scale Set Name' as label,
      scale_set_name as value
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "compute_virtual_machine_scale_set_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "compute_virtual_machine_scale_set_vm_overview" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_vm_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_compute_virtual_machine_scale_set_vm,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_vm_image_reference" {
  sql = <<-EOQ
    select
      virtual_machine_storage_profile -> 'imageReference' ->> 'offer' as "Offer",
      virtual_machine_storage_profile -> 'imageReference' ->> 'publisher' as "Publisher",
      virtual_machine_storage_profile -> 'imageReference' ->> 'sku' as "SKU",
      virtual_machine_storage_profile -> 'imageReference' ->> 'version' as "Version"
    from
      azure_compute_virtual_machine_scale_set_vm
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_vm_os_disks" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_vm_data_disks" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_vm_network_interface" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}
