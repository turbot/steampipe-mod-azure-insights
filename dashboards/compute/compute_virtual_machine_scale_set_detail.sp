dashboard "azure_compute_virtual_machine_scale_set_detail" {

  title         = "Azure Compute Virtual Machine Scale Set Detail"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_scale_set_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "vm_scale_set_id" {
    title = "Select a virtual machine scale set:"
    query = query.azure_compute_virtual_machine_scale_set_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_compute_virtual_machine_scale_set_status
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_scale_set_encryption_status
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_scale_set_logging_status
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

    card {
      width = 2
      query = query.azure_compute_virtual_machine_scale_set_log_analytics_agent
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_compute_virtual_machine_scale_set_node,
        node.azure_compute_virtual_machine_scale_set_to_scale_set_vm_node,
        node.azure_compute_virtual_machine_scale_set_to_backend_address_pool_node,
        node.azure_compute_virtual_machine_scale_set_backend_address_pool_to_load_balancer_node,
        node.azure_compute_virtual_machine_scale_set_to_application_gateway_node,
        node.azure_compute_virtual_machine_scale_set_to_network_interface_node,
        node.azure_compute_virtual_machine_scale_set_network_interface_to_subnet_node,
        node.azure_compute_virtual_machine_scale_set_network_interface_subnet_to_virtual_network_node
      ]

      edges = [
        edge.azure_compute_virtual_machine_scale_set_to_scale_set_vm_edge,
        edge.azure_compute_virtual_machine_scale_set_to_backend_address_pool_edge,
        edge.azure_compute_virtual_machine_scale_set_backend_address_pool_to_load_balancer_edge,
        edge.azure_compute_virtual_machine_scale_set_to_application_gateway_edge,
        edge.azure_compute_virtual_machine_scale_set_to_network_interface_edge,
        edge.azure_compute_virtual_machine_scale_set_network_interface_to_subnet_edge,
        edge.azure_compute_virtual_machine_scale_set_network_interface_subnet_to_virtual_network_edge
      ]

      args = {
        id = self.input.vm_scale_set_id.value
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
        query = query.azure_compute_virtual_machine_scale_set_overview
        args = {
          id = self.input.vm_scale_set_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_compute_virtual_machine_scale_set_tags
        args = {
          id = self.input.vm_scale_set_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "SKU"
        query = query.azure_compute_virtual_machine_scale_set_sku
        args = {
          id = self.input.vm_scale_set_id.value
        }
      }

      table {
        title = "Image Reference"
        query = query.azure_compute_virtual_machine_scale_set_image_reference
        args = {
          id = self.input.vm_scale_set_id.value
        }
      }

      table {
        title = "OS Disks"
        query = query.azure_compute_virtual_machine_scale_set_os_disks
        args = {
          id = self.input.vm_scale_set_id.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interface"
      query = query.azure_compute_virtual_machine_scale_set_network_interface
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Data Disks"
      query = query.azure_compute_virtual_machine_scale_set_data_disks
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

  }

}

query "azure_compute_virtual_machine_scale_set_input" {
  sql = <<-EOQ
    select
      v.title as label,
      v.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', v.resource_group,
        'region', v.region,
        'unique_id', v.unique_id
      ) as tags
    from
      azure_compute_virtual_machine_scale_set as v,
      azure_subscription as s
    where
      v.subscription_id = s.subscription_id
    order by
      v.title;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      provisioning_state as value
    from
      azure_compute_virtual_machine_scale_set
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_compute_virtual_machine_scale_set_encryption_status" {
  sql = <<-EOQ
    select
      'Host Encryption' as label,
      case
        when virtual_machine_security_profile -> 'encryptionAtHost' <> 'true' or virtual_machine_security_profile -> 'encryptionAtHost' is null
      then 'Disabled' else 'Enabled' end as value,
      case
        when virtual_machine_security_profile -> 'encryptionAtHost' <> 'true' or virtual_machine_security_profile -> 'encryptionAtHost' is null
      then 'alert' else 'ok' end as type
    from
      azure_compute_virtual_machine_scale_set
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_logging_status" {
  sql = <<-EOQ
     with logging_details as (
      select
        distinct a.id as vm_scale_set_id
      from
        azure_compute_virtual_machine_scale_set as a,
        jsonb_array_elements(extensions) as b
      where
        (b ->> 'Publisher' = 'Microsoft.Azure.Diagnostics'
        and b ->> 'ExtensionType' = 'IaaSDiagnostics'
        or
        (b ->> 'Publisher' = any(ARRAY ['Microsoft.OSTCExtensions', 'Microsoft.Azure.Diagnostics']))
        and b ->> 'ExtensionType' = 'LinuxDiagnostic')
    )
    select
      'Logging' as label,
      case
        when b.vm_scale_set_id is not null
      then 'Enabled'
      else 'Disabled' end as value,
      case
        when b.vm_scale_set_id is not null
      then 'ok'
      else 'alert' end as type
    from
      azure_compute_virtual_machine_scale_set as a
      left join logging_details as b on a.id = b.vm_scale_set_id
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_log_analytics_agent" {
  sql = <<-EOQ
    with agent_installed_vm_scale_set as (
      select
        distinct a.id as vm_id
      from
        azure_compute_virtual_machine_scale_set as a,
        jsonb_array_elements(extensions) as b
      where
        b ->> 'Publisher' = 'Microsoft.EnterpriseCloud.Monitoring'
        and b ->> 'ExtensionType' = any(ARRAY ['MicrosoftMonitoringAgent', 'OmsAgentForLinux'])
        and b ->> 'ProvisioningState' = 'Succeeded'
        and b -> 'Settings' ->> 'workspaceId' is not null
    )
    select
      'Log Analytics Agent' as label,
      case when b.vm_id is not null
      then 'Installed' else 'Not Installed' end as value,
      case when b.vm_id is not null then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine_scale_set as a
      left join agent_installed_vm_scale_set as b on a.id = b.vm_id
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      unique_id as "Scale Set ID",
      type as "Type",
      provisioning_state as "Provisioning State",
      identity ->> 'type' as "Identity",
      upgrade_policy ->> 'mode' as "Upgrade Policy Mode",
      region as "Region",
      resource_group as "Resource Group",
      id as "ID"
    from
      azure_compute_virtual_machine_scale_set
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_compute_virtual_machine_scale_set,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_sku" {
  sql = <<-EOQ
    select
      sku_name as "Name",
      sku_tier as "Tier",
      sku_capacity as "Capacity"
    from
      azure_compute_virtual_machine_scale_set
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_image_reference" {
  sql = <<-EOQ
    select
      virtual_machine_storage_profile -> 'imageReference' ->> 'offer' as "Offer",
      virtual_machine_storage_profile -> 'imageReference' ->> 'publisher' as "Publisher",
      virtual_machine_storage_profile -> 'imageReference' ->> 'sku' as "SKU",
      virtual_machine_storage_profile -> 'imageReference' ->> 'version' as "Version"
    from
      azure_compute_virtual_machine_scale_set
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_os_disks" {
  sql = <<-EOQ
    select
      virtual_machine_storage_profile -> 'osDisk' ->> 'caching' as "Caching",
      virtual_machine_storage_profile -> 'osDisk' ->> 'createOption' as "Create Option",
      virtual_machine_storage_profile -> 'osDisk' ->> 'diskSizeGB' as "Disk Size (GB)",
      virtual_machine_storage_profile -> 'osDisk' -> 'managedDisk' ->> 'storageAccountType' as "Storage Account Type",
      virtual_machine_storage_profile -> 'osDisk' ->> 'osType' as "OS Type"
    from
      azure_compute_virtual_machine_scale_set
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_network_interface" {
  sql = <<-EOQ
    select
      nic ->> 'name' as "Name",
      -- (nic -> 'properties' ->> 'enableAcceleratedNetworking')::boolean as "Enable Accelerated Networking",
      (nic -> 'properties' ->> 'enableIPForwarding')::boolean as "Enable IP Forwarding",
      (nic -> 'properties' ->> 'primary')::boolean as "Primary",
      -- nic -> 'properties' -> 'networkSecurityGroup' ->> 'id' as "Network Security Group ID",
      ip ->> 'name' as "IP Config Name",
      -- ip -> 'properties' -> 'loadBalancerBackendAddressPools' as "Load Balancer Backend Address Pools",
      -- ip -> 'properties' -> 'loadBalancerInboundNatPools' as "Load Balancer Inbound Nat Pools",
      (ip -> 'properties' ->> 'primary')::boolean as "IP Primary",
      ip -> 'properties' ->> 'privateIPAddressVersion' as "Private IP Address Version"
      -- ip -> 'properties' -> 'subnet' ->> 'id' as "IP Subnet ID"
    from
      azure_compute_virtual_machine_scale_set,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') nic,
      jsonb_array_elements(nic -> 'properties' -> 'ipConfigurations') ip
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_compute_virtual_machine_scale_set_data_disks" {
  sql = <<-EOQ
    select
      disk ->> 'caching' as "Caching",
      disk ->> 'createOption' as "Create Option",
      disk ->> 'diskSizeGB' as "Disk Size (GB)",
      disk ->> 'lun' as "Logical Unit Number",
      disk -> 'managedDisk' ->> 'storageAccountType' as "Storage Account Type",
      (disk -> 'writeAcceleratorEnabled')::boolean as "Write Accelerator Enabled"
    from
      azure_compute_virtual_machine_scale_set,
      jsonb_array_elements(virtual_machine_storage_profile -> 'dataDisks') as disk
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_node" {
  category = category.azure_compute_virtual_machine_scale_set

  sql = <<-EOQ
    select
      id as id,
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
      id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_to_scale_set_vm_node" {
  category = category.azure_compute_virtual_machine_scale_set_vm

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
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name and vm.resource_group = s.resource_group
    where
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_to_scale_set_vm_edge" {
  title = "instance"

  sql = <<-EOQ
    select
      s.id as from_id,
      vm.id as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name and vm.resource_group = s.resource_group
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_to_backend_address_pool_node" {
  category = category.azure_lb_backend_address_pool

  sql = <<-EOQ
    select
      pool.id as id,
      pool.title as title,
      jsonb_build_object(
        'Name', pool.name,
        'ID', pool.id,
        'Provisioning State', pool.provisioning_state,
        'Type', pool.type,
        'Subscription ID', pool.subscription_id,
        'Resource Group', pool.resource_group
      ) as properties
    from
      azure_compute_virtual_machine_scale_set as s,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
      jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
      jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools' ) as b
      left join azure_lb_backend_address_pool as pool on pool.id = b ->> 'id'
    where
      s.id = $1;
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_to_backend_address_pool_edge" {
  title = "backend address pool"

  sql = <<-EOQ
    select
      s.id as from_id,
      b ->> 'id' as to_id
    from
      azure_compute_virtual_machine_scale_set as s,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
      jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
      jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools' ) as b
      left join azure_lb_backend_address_pool as pool on pool.id = b ->> 'id'
    where
      s.id = $1;
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_backend_address_pool_to_load_balancer_node" {
  category = category.azure_lb

  sql = <<-EOQ
    with lb_backend_address_pool as (
      select
        b ->> 'id' as backend_address_pool_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
        jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
        jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools' ) as b
      where
        s.id = $1
    )
    select
      lb.id as id,
      lb.title as title,
      jsonb_build_object(
        'Name', lb.name,
        'ID', lb.id,
        'Type', lb.type,
        'Provisioning State', lb.provisioning_state,
        'Subscription ID', lb.subscription_id,
        'Resource Group', lb.resource_group
      ) as properties
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as p
    where
      p ->> 'id' in (select backend_address_pool_id from lb_backend_address_pool)
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_backend_address_pool_to_load_balancer_edge" {
  title = "load balancer"

  sql = <<-EOQ
    with lb_backend_address_pool as (
      select
        b ->> 'id' as backend_address_pool_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
        jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
        jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools' ) as b
      where
        s.id = $1
    )
    select
      p ->> 'id' as from_id,
      lb.id as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as p
    where
      p ->> 'id' in (select backend_address_pool_id from lb_backend_address_pool)
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_to_application_gateway_node" {
  category = category.azure_application_gateway

  sql = <<-EOQ
    with application_gateway_backend_address_pool as (
      select
        b ->> 'id' as backend_address_pool_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
        jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
        jsonb_array_elements(c -> 'properties' -> 'applicationGatewayBackendAddressPools' ) as b
      where
        s.id = $1
    )
    select
      g.id as id,
      g.title as title,
      jsonb_build_object(
        'Name', g.name,
        'ID', g.id,
        'Type', g.type,
        'Operational State', g.operational_state,
        'Provisioning State', g.provisioning_state,
        'Subscription ID', g.subscription_id,
        'Resource Group', g.resource_group
      ) as properties
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
      left join application_gateway_backend_address_pool as pool on pool.backend_address_pool_id = p ->> 'id'
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_to_application_gateway_edge" {
  title = "application gateway"

  sql = <<-EOQ
    with application_gateway_backend_address_pool as (
      select
        b ->> 'id' as backend_address_pool_id,
        s.id as scale_set_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
        jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
        jsonb_array_elements(c -> 'properties' -> 'applicationGatewayBackendAddressPools' ) as b
      where
        s.id = $1
    )
    select
      pool.scale_set_id as from_id,
      g.id as to_id
    from
      azure_application_gateway as g,
      jsonb_array_elements(backend_address_pools) as p
      left join application_gateway_backend_address_pool as pool on pool.backend_address_pool_id = p ->> 'id'
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_to_network_interface_node" {
  category = category.azure_compute_virtual_machine_scale_set_network_interface

  sql = <<-EOQ
    with nic_list as (
      select
        n ->> 'name' as nic_name
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') n
      where s.id = $1
    )
    select
      nic.name as id,
      nic.title as title,
      jsonb_build_object(
        'Name', nic.name,
        'Primary', nic.primary,
        'Provisioning State', nic.provisioning_state,
        'Enable Accelerated Networking', nic.enable_accelerated_networking,
        'Subscription ID', nic.subscription_id,
        'Resource Group', nic.resource_group,
        'Provisioning State', nic.provisioning_state,
        'Region', nic.region
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_network_interface as nic
    where
      nic.name = (select nic_name from nic_list ) limit 1
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_to_network_interface_edge" {
  title = "network interface"

  sql = <<-EOQ
    with nic_list as (
      select
        n ->> 'name' as nic_name,
        s.id as scale_set_id
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') n
      where s.id = $1
    )
    select
      (select scale_set_id from nic_list ) as from_id,
      nic.name as to_id
    from
      azure_compute_virtual_machine_scale_set_network_interface as nic
    where
      nic.name = (select nic_name from nic_list ) limit 1
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_network_interface_to_subnet_node" {
  category = category.azure_subnet

  sql = <<-EOQ
    with subnet_list as (
      select
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id,
        s.id as scale_set_id,
        n ->> 'name' as nic_name
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as n,
        jsonb_array_elements(n -> 'properties' -> 'ipConfigurations') as c
      where
        s.id = $1
    )
    select
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group
      ) as properties
    from
      subnet_list as l
      left join azure_subnet as s on s.id = l.subnet_id
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_network_interface_to_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    with subnet_list as (
      select
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id,
        s.id as scale_set_id,
        n ->> 'name' as nic_name
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as n,
        jsonb_array_elements(n -> 'properties' -> 'ipConfigurations') as c
      where
        s.id = $1
    )
    select
      l.nic_name as from_id,
      s.id as to_id
    from
      subnet_list as l
      left join azure_subnet as s on s.id = l.subnet_id
  EOQ

  param "id" {}
}

node "azure_compute_virtual_machine_scale_set_network_interface_subnet_to_virtual_network_node" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    with subnet_list as (
      select
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id,
        s.id as scale_set_id,
        n ->> 'name' as nic_name
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as n,
        jsonb_array_elements(n -> 'properties' -> 'ipConfigurations') as c
      where
        s.id = $1
    )
    select
      vn.id as id,
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
      s ->> 'id' in (select subnet_id from subnet_list)
  EOQ

  param "id" {}
}

edge "azure_compute_virtual_machine_scale_set_network_interface_subnet_to_virtual_network_edge" {
  title = "virtual network"

  sql = <<-EOQ
    with subnet_list as (
      select
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id,
        s.id as scale_set_id,
        n ->> 'name' as nic_name
      from
        azure_compute_virtual_machine_scale_set as s,
        jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as n,
        jsonb_array_elements(n -> 'properties' -> 'ipConfigurations') as c
      where
        s.id = $1
    )
    select
      s ->> 'id' as from_id,
      vn.id as to_id
    from
      azure_virtual_network as vn,
      jsonb_array_elements(vn.subnets) as s
    where
      s ->> 'id' in (select subnet_id from subnet_list)
  EOQ

  param "id" {}
}