dashboard "azure_compute_virtual_machine_scale_set_dashboard" {

  title         = "Azure Compute Virtual Machine Scale Set Dashboard"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_scale_set_dashboard.md")

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.azure_compute_virtual_machine_scale_set_count
      width = 2
    }

    card {
      query = query.azure_compute_virtual_machine_scale_set_host_encryption_count
      width = 2
    }

    # Assessments
    card {
      query   = query.azure_compute_virtual_machine_scale_set_logging_disabled
      width = 2
    }

    card {
      query = query.azure_compute_virtual_machine_scale_set_log_analytics_agent_installed_count
      width = 2
    }
  }

  container {

    title = "Assessments"

    chart {
      title = "Host Encryption Status"
      query = query.azure_compute_virtual_machine_scale_set_by_host_encryption_status
      type  = "donut"
      width = 2

      series "count" {
        point "encrypted" {
          color = "ok"
        }
        point "unencrypted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Logging Status"
      query = query.azure_compute_virtual_machine_scale_set_by_logging_status
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Log Analytic Agent Status"
      query = query.azure_compute_virtual_machine_scale_set_by_log_analytics_agent_installed_status
      type  = "donut"
      width = 2

      series "count" {
        point "installed" {
          color = "ok"
        }
        point "not installed" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Scale Sets by Subscription"
      query = query.azure_compute_virtual_machine_scale_set_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Scale Sets by Resource Group"
      query = query.azure_compute_virtual_machine_scale_set_by_resource_group
      type  = "column"
      width = 3
    }

    chart {
      title = "Scale Sets by Region"
      query = query.azure_compute_virtual_machine_scale_set_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Scale Sets by Tier"
      query = query.azure_compute_virtual_machine_scale_set_by_tier
      type  = "column"
      width = 3
    }
  }

}

# Card Queries

query "azure_compute_virtual_machine_scale_set_count" {
  sql = <<-EOQ
    select count(*) as "Virtual Machine Scale Sets" from azure_compute_virtual_machine_scale_set;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_host_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted Host' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine_scale_set
    where
      virtual_machine_security_profile -> 'encryptionAtHost' <> 'true'
      or virtual_machine_security_profile -> 'encryptionAtHost' is null;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_logging_disabled" {
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
      count(*) as value,
      'Logging Disabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine_scale_set as a
      left join logging_details as b on a.id = b.vm_scale_set_id
    where
      b.vm_scale_set_id is null;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_log_analytics_agent_installed_count" {
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
      count(*) as value,
      'Log Analytics Agent Installed' as label,
      case count(*) when 0 then 'alert' else 'ok' end as type
    from
      azure_compute_virtual_machine_scale_set as a
      left join agent_installed_vm_scale_set as b on a.id = b.vm_id
    where
      b.vm_id is not null;
  EOQ
}

# Assessment Queries

query "azure_compute_virtual_machine_scale_set_by_host_encryption_status" {
  sql = <<-EOQ
    select
      encryption,
      count(*)
    from (
      select virtual_machine_security_profile -> 'encryptionAtHost',
        case when virtual_machine_security_profile -> 'encryptionAtHost' <> 'true' or virtual_machine_security_profile -> 'encryptionAtHost' is null then 'unencrypted'
        else 'encrypted'
        end encryption
      from
        azure_compute_virtual_machine_scale_set) as vmss
    group by
      encryption
    order by
      encryption;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_by_logging_status" {
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
      set_id,
      count(*)
    from (
      select b.vm_scale_set_id,
        case when b.vm_scale_set_id is not null then
          'enabled'
        else
          'disabled'
        end set_id
      from
        azure_compute_virtual_machine_scale_set as a
        left join logging_details as b on a.id = b.vm_scale_set_id) as vmss
    group by
      set_id
    order by
      set_id;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_by_log_analytics_agent_installed_status" {
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
      status,
      count(*)
    from (
      select
        b.vm_id,
        case when b.vm_id is not null then
          'installed'
        else
          'not installed'
        end status
      from
        azure_compute_virtual_machine_scale_set as a
        left join agent_installed_vm_scale_set as b on a.id = b.vm_id) as vmss
    group by
      status
    order by
      status;
  EOQ
}

# Analysis Queries

query "azure_compute_virtual_machine_scale_set_by_subscription" {
  sql = <<-EOQ
    select
      a.title as "Subscription",
      count(vmss.*) as "Scale Sets"
    from
      azure_compute_virtual_machine_scale_set as vmss,
      azure_subscription as a
    where
      a.subscription_id = vmss.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(s.*) as "Scale Sets"
    from
      azure_compute_virtual_machine_scale_set as s,
      azure_subscription as sub
    where
       s.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Scale sets"
    from
      azure_compute_virtual_machine_scale_set
    group by
      region
    order by
      region;
  EOQ
}

query "azure_compute_virtual_machine_scale_set_by_tier" {
  sql = <<-EOQ
    select
      sku_tier as "Tier",
      count(sku_tier) as "Scale sets"
    from
      azure_compute_virtual_machine_scale_set
    group by
      sku_tier
    order by
      sku_tier;
  EOQ
}
