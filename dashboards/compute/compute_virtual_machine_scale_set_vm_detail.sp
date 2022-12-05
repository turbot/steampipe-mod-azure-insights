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

      with "subnets" {
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

      with "virtual_networks" {
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

      with "virtual_machine_scale_sets" {
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


      nodes = [
        node.compute_disk,
        node.compute_virtual_machine_scale_set_vm_to_backend_address_pool,
        node.compute_virtual_machine_scale_set_vm_to_scale_set_network_interface,
        node.compute_virtual_machine_scale_set_vm,
        node.compute_virtual_machine_scale_set,
        node.network_load_balancer,
        node.network_network_security_group,
        node.network_subnet,
        node.network_virtual_network,
      ]

      edges = [
        edge.azure_compute_virtual_machine_scale_set_to_virtual_machine_scale_set_vm,
        edge.compute_virtual_machine_scale_set_vm_to_backend_address_pool,
        edge.compute_virtual_machine_scale_set_vm_to_compute_disk,
        edge.compute_virtual_machine_scale_set_vm_to_load_balaner,
        edge.compute_virtual_machine_scale_set_vm_to_network_security_group,
        edge.compute_virtual_machine_scale_set_vm_to_scale_set_network_interface,
        edge.compute_virtual_machine_scale_set_vm_to_subnet,
        edge.compute_virtual_machine_scale_set_vm_to_virtual_network,

      ]

      args = {
        compute_disk_ids                         = with.compute_disks.rows[*].disk_id
        compute_virtual_machine_scale_set_ids    = with.virtual_machine_scale_sets.rows[*].scale_set_id
        compute_virtual_machine_scale_set_vm_ids = [self.input.scale_set_vm_id.value]
        network_load_balancer_ids                = with.network_load_balancers.rows[*].lb_id
        network_security_group_ids               = with.network_security_groups.rows[*].nsg_id
        network_subnet_ids                       = with.subnets.rows[*].subnet_id
        virtual_network_ids                      = with.virtual_networks.rows[*].network_id

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

node "compute_virtual_machine_scale_set_vm" {
  category = category.compute_virtual_machine_scale_set_vm

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
      lower(id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

node "compute_virtual_machine_scale_set_vm_to_scale_set_network_interface" {
  category = category.compute_virtual_machine_scale_set_network_interface

  sql = <<-EOQ
    select
      lower(nic.id) as id,
      nic.title as title,
      jsonb_build_object(
        'Name', nic.name,
        'ID', nic.id,
        'Primary', nic.primary,
        'Enable Accelerated Networking', nic.enable_accelerated_networking,
        'Subscription ID', nic.subscription_id,
        'Resource Group', nic.resource_group,
        'Region', nic.region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
    where
      lower(vm.id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

edge "compute_virtual_machine_scale_set_vm_to_scale_set_network_interface" {
  title = "network interface"

  sql = <<-EOQ
    select
      lower(vm.id) as from_id,
      lower(nic.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
    where
      lower(vm.id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

node "compute_virtual_machine_scale_set_vm_network_interface_to_network_security_group_node" {
  category = category.network_security_group

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
      lower(vm.id) = $1;
  EOQ

  param "id" {}
}

edge "compute_virtual_machine_scale_set_vm_to_network_security_group" {
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
      lower(vm.id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

node "compute_virtual_machine_scale_set_vm_to_backend_address_pool" {
  category = category.network_load_balancer_backend_address_pool

  sql = <<-EOQ
    with compute_virtual_machine_scale_set_network_interface as (
      select
        nic.id as nic_id,
        lower(c ->> 'id') as config_id
      from
        azure_compute_virtual_machine_scale_set_network_interface as nic,
        jsonb_array_elements(ip_configurations) as c
      where
        lower(nic.virtual_machine ->> 'id') = any($1)
    )
    select
      lower(p.id) as id,
      p.title as title,
      jsonb_build_object(
        'Name', p.name,
        'ID', p.id,
        'Subscription ID', p.subscription_id,
        'Resource Group', p.resource_group
      ) as properties
    from
      azure_lb_backend_address_pool as p,
      jsonb_array_elements(backend_ip_configurations) as c
    where
      lower(c ->> 'id') in (select config_id from compute_virtual_machine_scale_set_network_interface)
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

edge "compute_virtual_machine_scale_set_vm_to_backend_address_pool" {
  title = "backend address pool"

  sql = <<-EOQ
    with compute_virtual_machine_scale_set_network_interface as (
      select
        nic.id as nic_id,
        c ->> 'id' as config_id
      from
        azure_compute_virtual_machine_scale_set_network_interface as nic,
        jsonb_array_elements(ip_configurations) as c
      where
        lower(nic.virtual_machine ->> 'id') = any($1)
    )
    select
      lower(nic.nic_id) as from_id,
      lower(p.id) as to_id
    from
      azure_lb_backend_address_pool as p,
      jsonb_array_elements(backend_ip_configurations) as c,
      compute_virtual_machine_scale_set_network_interface as nic
    where
      c ->> 'id' in (select config_id from compute_virtual_machine_scale_set_network_interface)
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}


node "compute_virtual_machine_scale_set_vm_network_interface_backend_address_pool_to_lb_node" {
  category = category.network_load_balancer

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
      lower(lb.id) as id,
      lb.title as title,
      jsonb_build_object(
        'Name', lb.name,
        'ID', lb.id,
        'Etag', lb.etag,
        'SKU Name', lb.sku_name,
        'Subscription ID', lb.subscription_id,
        'Resource Group', lb.resource_group
      ) as properties
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as p
      left join backend_address_pool as pool on pool.id = lower(p ->> 'id')
  EOQ

  param "id" {}
}

edge "compute_virtual_machine_scale_set_vm_to_load_balaner" {
  title = "lb"

  sql = <<-EOQ
    with compute_virtual_machine_scale_set_network_interface as (
      select
        nic.id as nic_id,
        c ->> 'id' as config_id
      from
        azure_compute_virtual_machine_scale_set_network_interface as nic,
        jsonb_array_elements(ip_configurations) as c
      where
        lower(nic.virtual_machine ->> 'id') = any($1)
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
      lower(p ->> 'id') as from_id,
      lower(lb.id) as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as p
      left join backend_address_pool as pool on pool.id = lower(p ->> 'id')
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

node "compute_virtual_machine_scale_set_vm_network_interface_to_subnet_node" {
  category = category.network_subnet

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

edge "compute_virtual_machine_scale_set_vm_to_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with ip_configs as (
      select
        nic.ip_configurations as ip_config,
        nic.network_security_group ->> 'id' as nsg_id,
        lower(vm.id) as vm_id,
        lower(nic.id) as nic_id
      from
        azure_compute_virtual_machine_scale_set_vm as vm
        left join azure_compute_virtual_machine_scale_set_network_interface as nic on lower(vm.id) = lower(nic.virtual_machine ->> 'id')
      where
        lower(vm.id) = any($1)
    )
    select
      coalesce(
        lower(config.nsg_id),
        lower(config.nic_id)
      ) as from_id,
      lower(s.id) as to_id
    from
      ip_configs as config,
      jsonb_array_elements(ip_config) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id');
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

node "compute_virtual_machine_scale_set_vm_network_interface_subnet_to_virtual_network_node" {
  category = category.network_virtual_network

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

edge "compute_virtual_machine_scale_set_vm_to_virtual_network" {
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
        lower(vm.id) = any($1)
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

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

node "azure_compute_virtual_machine_scale_set_vm_to_compute_disk_node" {
  category = category.compute_disk

  sql = <<-EOQ
    select
      lower(d.id) as id,
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
      lower(vm.id) = $1;
  EOQ

  param "id" {}
}

edge "compute_virtual_machine_scale_set_vm_to_compute_disk" {
  title = "data disk"

  sql = <<-EOQ
    select
      lower(vm.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm,
      jsonb_array_elements(virtual_machine_storage_profile -> 'dataDisks') as disk
      left join azure_compute_disk as d on lower(d.id) = lower(disk -> 'managedDisk' ->> 'id')
    where
      lower(vm.id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}

node "azure_compute_virtual_machine_scale_set_vm_from_vm_scale_set_node" {
  category = category.compute_virtual_machine_scale_set

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
      lower(vm.id) = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_to_virtual_machine_scale_set_vm" {
  title = "scale set vm"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(vm.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name
    where
      lower(vm.id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_vm_ids" {}
}
