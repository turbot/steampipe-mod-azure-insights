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
      title as label,
      id as value,
      json_build_object(
        'resource_group', resource_group,
        'region', region,
        'unique_id', unique_id
      ) as tags
    from
      azure_compute_virtual_machine_scale_set
    order by
      title;
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
