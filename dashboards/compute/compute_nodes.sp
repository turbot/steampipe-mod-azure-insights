node "compute_disk" {
  category = category.compute_disk

  sql = <<-EOQ
    select
      lower(id) as id,
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
      lower(id) = any($1);
  EOQ

  param "compute_disk_ids" {}
}

node "compute_disk_access" {
  category = category.compute_disk_access

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Provisioning State', provisioning_state,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_compute_disk_access
    where
      lower(id) = any($1);
  EOQ

  param "compute_disk_access_ids" {}
}

node "compute_disk_encryption_set" {
  category = category.compute_disk_encryption_set

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_compute_disk_encryption_set
    where
      lower(id) = any($1);
  EOQ

  param "compute_disk_encryption_set_ids" {}
}

node "compute_image" {
  category = category.compute_image

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_compute_image
    where
      lower(id) = any($1);
  EOQ

  param "compute_image_ids" {}
}

node "compute_snapshot" {
  category = category.compute_snapshot

  sql = <<-EOQ
    select
      lower(id) as id,
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
      azure_compute_snapshot
    where
      lower(id) = any($1);
  EOQ

  param "compute_snapshot_ids" {}
}

node "compute_virtual_machine" {
  category = category.compute_virtual_machine

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

node "compute_virtual_machine_application_gateway_backend_address_pool" {
  category = category.network_load_balancer_backend_address_pool

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
        lower(vm.id) = any($1)
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

  param "compute_virtual_machine_ids" {}
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

node "compute_virtual_machine_scale_set_network_interface" {
  category = category.compute_virtual_machine_scale_set_network_interface

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Enable Accelerated Networking', enable_accelerated_networking,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_network_interface
    where
      lower(id) = any($1);
  EOQ

  param "compute_virtual_machine_scale_set_network_interface_ids" {}
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

