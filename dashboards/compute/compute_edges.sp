edge "compute_disk_encryption_set_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key_version as v
      left join azure_compute_disk_encryption_set as s on s.active_key_url = v.key_uri_with_version
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "compute_disk_to_storage_storage_account" {
  title = "blob source for disk"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_disk as d
      left join azure_storage_account as a on lower(a.id) = lower(d.creation_data_storage_account_id)
    where
      lower(d.id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

edge "compute_snapshot_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(storage_account_id) as to_id
    from
      azure_compute_snapshot
    where
      lower(storage_account_id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "compute_virtual_machine_to_network_network_interface" {
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
      lower(n.id) as to_id,
      lower(vn.id) as from_id
    from
      network_interface_id as vn
      left join azure_network_interface as n on lower(vn.n_id) = lower(n.id)
    where
      lower(vn.id) = any($1);
  EOQ

  param "compute_virtual_machine_ids" {}
}

edge "compute_virtual_machine_to_compute_image" {
  title = "uses"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(i.id) as to_id
    from
      azure_compute_image as i
      left join azure_compute_virtual_machine as v on lower(i.id) = lower(v.image_id)
    where
      lower(v.id) = any($1);
  EOQ

  param "compute_virtual_machine_ids" {}
}

edge "compute_virtual_machine_to_compute_data_disk" {
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
      lower(v.id) = any($1);
  EOQ

  param "compute_virtual_machine_ids" {}
}

edge "compute_virtual_machine_to_compute_os_disk" {
  title = "os disk"

  sql = <<-EOQ
    select
      lower(vm.id) as from_id,
      lower(d.id) as to_id
    from
      azure_compute_virtual_machine as vm
      left join azure_compute_disk as d on lower(d.managed_by) = lower(vm.id)
    where
      lower(vm.id) = any($1);
  EOQ

  param "compute_virtual_machine_ids" {}
}


edge "compute_virtual_machine_to_network_public_ip" {
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
        lower(vm.id) = any($1)
    )
    select
      lower(n.nic_id) as from_id,
      lower(p.id) as to_id
    from
      network_interfaces as n,
      jsonb_array_elements(ip_configuration) as ip_config
      left join azure_public_ip as p on lower(p.id) = lower(ip_config -> 'properties' -> 'publicIPAddress' ->> 'id');
  EOQ

  param "compute_virtual_machine_ids" {}
}

edge "compute_virtual_machine_to_network_virtual_network" {
  title = "virtual network"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        lower(id) = any($1)
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
      lower(vn.id) as to_id,
      lower(sub.id) as from_id
    from
      azure_virtual_network as vn,
      jsonb_array_elements(subnets) as s
      left join subnet_id as sub on lower(sub.id) = lower(s ->> 'id')
    where
      lower(s ->> 'id') in (select lower(id) from subnet_id);
  EOQ

  param "compute_virtual_machine_ids" {}
}

edge "compute_virtual_machine_to_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
      where
        lower(id) = any($1)
    )
    select
      lower(s.id) as to_id,
      lower(n.id) as from_id
    from
      network_interface_id as vn
      left join azure_network_interface as n on lower(vn.n_id) = lower(n.id)
      left join azure_network_security_group as s on lower(n.network_security_group_id) = lower(s.id)
  EOQ

  param "compute_virtual_machine_ids" {}
}

edge "compute_virtual_machine_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as nic_id
      from
        azure_compute_virtual_machine
      where
        lower(id) = any($1)
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

  param "compute_virtual_machine_ids" {}
}

edge "compute_virtual_machine_scale_set_to_compute_virtual_machine_scale_set_network_interface" {
  title = "network interface"

  sql = <<-EOQ
    with nic_list as (
      select
        n ->> 'name' as nic_name,
        lower(s.id) as scale_set_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') n
      where
        lower(s.id) = any($1)
    )
    select
      (select lower(scale_set_id) from nic_list ) as from_id,
      lower(nic.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_network_interface as nic
    where
      nic.name = (select nic_name from nic_list ) limit 1
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

edge "compute_virtual_machine_scale_set_to_network_load_balancer_backend_address_pool" {
  title = "backend address pool"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(b ->> 'id') as to_id
    from
      azure_compute_virtual_machine_scale_set as s,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
      jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
      jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools' ) as b
      left join azure_lb_backend_address_pool as pool on lower(pool.id) = lower(b ->> 'id')
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

edge "compute_virtual_machine_scale_set_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with subnet_list as (
      select
        n -> 'properties' -> 'networkSecurityGroup' ->> 'id' as nsg_id,
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id,
        lower(s.id) as scale_set_id,
        n ->> 'name' as nic_name
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as n,
        jsonb_array_elements(n -> 'properties' -> 'ipConfigurations') as c
      where
        lower(s.id) = any($1)
    )
    select
      coalesce(
        lower(l.nsg_id),
        l.nic_name
      ) as from_id,
      lower(s.id) as to_id
    from
      subnet_list as l
      left join azure_subnet as s on lower(s.id) = lower(l.subnet_id);
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

edge "compute_virtual_machine_scale_set_to_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    with nic_list as (
      select
        lower(n -> 'properties' -> 'networkSecurityGroup' ->> 'id') as nsg_id,
        nic.id as nic_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') n
        left join azure_compute_virtual_machine_scale_set_network_interface as nic on nic.name = n ->> 'name'
      where
        lower(s.id) = any($1) limit 1
    )
    select
      lower(nic.nic_id) as from_id,
      lower(nsg.id) as to_id
    from
      nic_list as nic
      left join azure_network_security_group as nsg on lower(nsg.id) = lower(nic.nsg_id)
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

edge "compute_virtual_machine_scale_set_to_network_application_gateway" {
  title = "application gateway"

  sql = <<-EOQ
    with application_gateway_backend_address_pool as (
      select
        lower(b ->> 'id') as backend_address_pool_id,
        lower(s.id ) as scale_set_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
        jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
        jsonb_array_elements(c -> 'properties' -> 'applicationGatewayBackendAddressPools' ) as b
      where
        lower(s.id) = $1
    )
    select
      lower(pool.scale_set_id) as from_id,
      lower(g.id) as to_id
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
      left join application_gateway_backend_address_pool as pool on lower(pool.backend_address_pool_id) = lower(p ->> 'id')
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

edge "compute_virtual_machine_scale_set_to_network_load_balancer" {
  title = "load balancer"

  sql = <<-EOQ
    with lb_backend_address_pool as (
      select
        lower(b ->> 'id') as backend_address_pool_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
        jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
        jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools' ) as b
      where
        lower(s.id) = any($1)
    )
    select
      lower(p ->> 'id') as from_id,
      lower(lb.id) as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as p
    where
      lower(p ->> 'id') in (select backend_address_pool_id from lb_backend_address_pool)
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

edge "compute_virtual_machine_scale_set_to_compute_virtual_machine_scale_set_vms" {
  title = "instance"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(vm.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name and vm.resource_group = s.resource_group
    where
      lower(s.id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

node "compute_virtual_machine_scale_set" {
  category = category.compute_virtual_machine_scale_set

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Unique ID', unique_id,
        'SKU Name', sku_name,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Provisioning State', provisioning_state,
        'Region', region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set
    where
      lower(id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_ids" {}
}

edge "compute_virtual_machine_scale_set_vm_to_compute_virtual_machine_scale_set_network_interface" {
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

edge "compute_virtual_machine_scale_set_vm_to_network_load_balancer_backend_address_pool" {
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

edge "compute_virtual_machine_scale_set_vm_to_network_load_balaner" {
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

edge "compute_virtual_machine_scale_set_vm_to_network_subnet" {
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

edge "compute_virtual_machine_scale_set_to_compute_virtual_machine_scale_set_vm" {
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