dashboard "compute_virtual_machine_scale_set_detail" {

  title         = "Azure Compute Virtual Machine Scale Set Detail"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_scale_set_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "vm_scale_set_id" {
    title = "Select a virtual machine scale set:"
    query = query.compute_virtual_machine_scale_set_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.compute_virtual_machine_scale_set_status
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

    card {
      width = 2
      query = query.compute_virtual_machine_scale_set_encryption_status
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

    card {
      width = 2
      query = query.compute_virtual_machine_scale_set_logging_status
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

    card {
      width = 2
      query = query.compute_virtual_machine_scale_set_log_analytics_agent
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

      with "compute_virtual_machine_scale_set_network_interfaces" {
        sql = <<-EOQ
          with nic_list as (
            select
              n ->> 'name' as nic_name
            from
              azure_compute_virtual_machine_scale_set as s,
              jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') n
            where
              lower(s.id) = $1
          )
          select
            lower(nic.id) as network_interface_id
          from
            azure_compute_virtual_machine_scale_set_network_interface as nic
          where
            nic.name = (select nic_name from nic_list ) limit 1
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "compute_virtual_machine_scale_set_vms" {
        sql = <<-EOQ
          select
            lower(vm.id) as scale_set_vm_id
          from
            azure_compute_virtual_machine_scale_set_vm as vm
            left join azure_compute_virtual_machine_scale_set as s on s.name = vm.scale_set_name and vm.resource_group = s.resource_group
          where
            lower(s.id) = $1;
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "kubernetes_clusters" {
        sql = <<-EOQ
          select
            lower(c.id) as cluster_id
          from
            azure_kubernetes_cluster c,
            azure_compute_virtual_machine_scale_set as set
          where
            lower(set.resource_group) = lower(c.node_resource_group)
            and lower(c.id) = $1;
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "network_application_gateways" {
        sql = <<-EOQ
          with application_gateway_backend_address_pool as (
            select
              lower(b ->> 'id') as backend_address_pool_id
            from
                azure_compute_virtual_machine_scale_set as s,
                jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
                jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
                jsonb_array_elements(c -> 'properties' -> 'applicationGatewayBackendAddressPools' ) as b
            where
              lower(s.id) = $1
          )
          select
            lower(g.id) as application_gateway_id
          from
            azure_application_gateway as g,
            jsonb_array_elements(backend_address_pools) as p
            left join application_gateway_backend_address_pool as pool on lower(pool.backend_address_pool_id) = lower(p ->> 'id')
          where
            pool.backend_address_pool_id is not null
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "network_load_balancer_backend_address_pools" {
        sql = <<-EOQ
          select
            lower(pool.id) as pool_id
          from
            azure_compute_virtual_machine_scale_set as s,
            jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations' ) as p,
            jsonb_array_elements(p -> 'properties' -> 'ipConfigurations' ) as c,
            jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools' ) as b
            left join azure_lb_backend_address_pool as pool on lower(pool.id) = lower(b ->> 'id')
          where
            lower(s.id) = $1;
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "network_load_balancers" {
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
              lower(s.id) = $1
          )
          select
            lower(lb.id) as lb_id
          from
            azure_lb as lb,
            jsonb_array_elements(backend_address_pools) as p
          where
            lower(p ->> 'id') in (select lower(backend_address_pool_id) from lb_backend_address_pool)
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "network_security_groups" {
        sql = <<-EOQ
          with nic_list as (
            select
              lower(n -> 'properties' -> 'networkSecurityGroup' ->> 'id') as nsg_id,
              n ->> 'name' as nic_name
            from
              azure_compute_virtual_machine_scale_set as s,
              jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') n
            where
              lower(s.id) = $1
          )
          select
            lower(nsg.id) as nsg_id
          from
            nic_list as nic
            left join azure_network_security_group as nsg on lower(nsg.id) = lower(nic.nsg_id)
          limit 1
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "network_subnets" {
        sql = <<-EOQ
          with subnet_list as (
            select
              lower(c -> 'properties' -> 'subnet' ->> 'id') as subnet_id,
              lower(s.id)as scale_set_id,
              n ->> 'name' as nic_name
            from
              azure_compute_virtual_machine_scale_set as s,
              jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as n,
              jsonb_array_elements(n -> 'properties' -> 'ipConfigurations') as c
            where
              lower(s.id) = $1
          )
          select
            lower(s.id) as subnet_id
          from
            subnet_list as l
            left join azure_subnet as s on lower(s.id) = lower(l.subnet_id)
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      with "network_virtual_networks" {
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
              lower(s.id) = $1
          )
          select
            lower(vn.id) as network_id
          from
            azure_virtual_network as vn,
            jsonb_array_elements(vn.subnets) as s
           where
            lower(s ->> 'id') in (select lower(subnet_id) from subnet_list)
          EOQ

        args = [self.input.vm_scale_set_id.value]
      }

      nodes = [
        node.compute_virtual_machine_scale_set,
        node.compute_virtual_machine_scale_set_network_interface,
        node.compute_virtual_machine_scale_set_vm,
        node.kubernetes_cluster,
        node.network_application_gateway,
        node.network_load_balancer,
        node.network_load_balancer_backend_address_pool,
        node.network_network_security_group,
        node.network_subnet,
        node.network_virtual_network
      ]

      edges = [
        edge.compute_virtual_machine_scale_set_to_compute_virtual_machine_scale_set_network_interface,
        edge.compute_virtual_machine_scale_set_to_compute_virtual_machine_scale_set_vms,
        edge.compute_virtual_machine_scale_set_to_network_application_gateway,
        edge.compute_virtual_machine_scale_set_to_network_load_balancer,
        edge.compute_virtual_machine_scale_set_to_network_load_balancer_backend_address_pool,
        edge.compute_virtual_machine_scale_set_to_network_security_group,
        edge.compute_virtual_machine_scale_set_to_network_subnet,
        edge.kubernetes_cluster_to_compute_virtual_machine_scale_set,
        edge.network_subnet_to_network_virtual_network
      ]

      args = {
        compute_virtual_machine_scale_set_ids                   = [self.input.vm_scale_set_id.value]
        compute_virtual_machine_scale_set_network_interface_ids = with.compute_virtual_machine_scale_set_network_interfaces.rows[*].network_interface_id
        compute_virtual_machine_scale_set_vm_ids                = with.compute_virtual_machine_scale_set_vms.rows[*].scale_set_vm_id
        kubernetes_cluster_ids                                  = with.kubernetes_clusters.rows[*].cluster_id
        network_application_gateway_ids                         = with.network_application_gateways.rows[*].application_gateway_id
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
        query = query.compute_virtual_machine_scale_set_overview
        args = {
          id = self.input.vm_scale_set_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_virtual_machine_scale_set_tags
        args = {
          id = self.input.vm_scale_set_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "SKU"
        query = query.compute_virtual_machine_scale_set_sku
        args = {
          id = self.input.vm_scale_set_id.value
        }
      }

      table {
        title = "Image Reference"
        query = query.compute_virtual_machine_scale_set_image_reference
        args = {
          id = self.input.vm_scale_set_id.value
        }
      }

      table {
        title = "OS Disks"
        query = query.compute_virtual_machine_scale_set_os_disks
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
      query = query.compute_virtual_machine_scale_set_network_interface
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Data Disks"
      query = query.compute_virtual_machine_scale_set_data_disks
      args = {
        id = self.input.vm_scale_set_id.value
      }
    }

  }

}

query "compute_virtual_machine_scale_set_input" {
  sql = <<-EOQ
    select
      v.title as label,
      lower(v.id) as value,
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
      lower(v.subscription_id) = lower(s.subscription_id)
    order by
      v.title;
  EOQ
}

query "compute_virtual_machine_scale_set_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      provisioning_state as value
    from
      azure_compute_virtual_machine_scale_set
    where
      lower(id) = $1;
  EOQ

  param "id" {}

}

query "compute_virtual_machine_scale_set_encryption_status" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_logging_status" {
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
      left join logging_details as b on lower(a.id) = lower(b.vm_scale_set_id)
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_log_analytics_agent" {
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
      left join agent_installed_vm_scale_set as b on lower(a.id) = lower(b.vm_id)
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_overview" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_compute_virtual_machine_scale_set,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_sku" {
  sql = <<-EOQ
    select
      sku_name as "Name",
      sku_tier as "Tier",
      sku_capacity as "Capacity"
    from
      azure_compute_virtual_machine_scale_set
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_image_reference" {
  sql = <<-EOQ
    select
      virtual_machine_storage_profile -> 'imageReference' ->> 'offer' as "Offer",
      virtual_machine_storage_profile -> 'imageReference' ->> 'publisher' as "Publisher",
      virtual_machine_storage_profile -> 'imageReference' ->> 'sku' as "SKU",
      virtual_machine_storage_profile -> 'imageReference' ->> 'version' as "Version"
    from
      azure_compute_virtual_machine_scale_set
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_os_disks" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_network_interface" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "compute_virtual_machine_scale_set_data_disks" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}
