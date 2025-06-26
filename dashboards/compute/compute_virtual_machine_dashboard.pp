dashboard "compute_virtual_machine_dashboard" {

  title         = "Azure Compute Virtual Machine Dashboard"
  documentation = file("./dashboards/compute/docs/compute_virtual_machine_dashboard.md")

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.compute_virtual_machine_count
      width = 2
      href = dashboard.compute_virtual_machine_inventory_report.url_path
    }

    card {
      query = query.compute_virtual_machine_host_encryption_count
      width = 2
    }

    card {
      query = query.compute_public_virtual_machine_count
      width = 2
    }

    card {
      query = query.compute_virtual_machine_vulnerability_assessment_disabled_count
      width = 2
    }

    card {
      query = query.compute_virtual_machine_unattached_with_network_count
      width = 2
    }

    card {
      query = query.compute_virtual_machine_unrestricted_remote_access_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Host Encryption Status"
      query = query.compute_virtual_machine_by_host_encryption_status
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
      title = "Public/Private"
      query = query.compute_virtual_machine_by_public_ip
      type  = "donut"
      width = 2

      series "count" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Vulnerability Assessment"
      query = query.compute_virtual_machine_by_vulnerability_assessment_solution
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
      title = "Network Attachment Status"
      query = query.compute_virtual_machine_by_attachment_to_network
      type  = "donut"
      width = 2

      series "count" {
        point "attached" {
          color = "ok"
        }
        point "unattached" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Unrestricted Remote Access"
      query   = query.compute_virtual_machine_by_remote_access
      type  = "donut"
      width = 2

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Disaster Recovery Status"
      query = query.compute_virtual_machine_by_disaster_recovery_status
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

  }

  container {

    title = "Analysis"

    chart {
      title = "Virtual Machines by Subscription"
      query = query.compute_virtual_machine_by_subscription
      type  = "column"
      width = 4
    }

    chart {
      title = "Virtual Machines by Resource Group"
      query = query.compute_virtual_machine_by_resource_group
      type  = "column"
      width = 4
    }

    chart {
      title = "Virtual Machines by Region"
      query = query.compute_virtual_machine_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Virtual Machines by OS Type"
      query = query.compute_virtual_machine_by_os_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Virtual Machines by Size"
      query = query.compute_virtual_machine_by_size
      type  = "column"
      width = 4
    }
  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      query = query.compute_virtual_machine_top10_cpu_past_week
      type  = "line"
      width = 6
    }

    chart {
      title = "Average Max Daily CPU - Last 30 days"
      query = query.compute_virtual_machine_by_cpu_utilization_category
      type  = "column"
      width = 6
    }

  }
}

# Card Queries

query "compute_virtual_machine_count" {
  sql = <<-EOQ
    select count(*) as "Virtual Machines" from azure_compute_virtual_machine;
  EOQ
}

query "compute_virtual_machine_host_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted Host' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine
    where
      security_profile -> 'encryptionAtHost' <> 'true' or security_profile -> 'encryptionAtHost' is null;
  EOQ
}

query "compute_public_virtual_machine_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_compute_virtual_machine
    where
      public_ips is not null
  EOQ
}

query "compute_virtual_machine_disaster_recovery_disabled_count" {
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
      count(*) as value,
      'Disaster Recovery Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine as vm
      where lower(vm.id) not in (select source_id from azure_resource_link) ;
  EOQ
}

query "compute_virtual_machine_unattached_with_network_count" {
  sql = <<-EOQ
    with vm_with_network_interfaces as (
      select
        vm.id as vm_id,
        n ->> 'id' as network_id
      from
        azure_compute_virtual_machine as vm,
        jsonb_array_elements(network_interfaces) as n
    )
    select
      count(*) as value,
      'Unattached With Network' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      vm_with_network_interfaces as vn
      left join azure_network_interface as i on i.id = vn.network_id
    where exists (
      select
        ip -> 'properties' -> 'subnet' ->> 'id' as ip
      from
        azure_network_interface,
        jsonb_array_elements(ip_configurations) as ip
      where
        ip -> 'properties' -> 'subnet' ->> 'id' is null
    )
  EOQ
}

query "compute_virtual_machine_unrestricted_remote_access_count" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name as sg_name,
        network_interfaces
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(security_rules) as sg,
        jsonb_array_elements_text(
          case
            when jsonb_array_length(sg -> 'properties' -> 'destinationPortRanges') > 0 then (sg -> 'properties' -> 'destinationPortRanges')
            else jsonb_build_array(sg -> 'properties' -> 'destinationPortRange')
          end ) as dport,
        jsonb_array_elements_text(
          case
            when jsonb_array_length(sg -> 'properties' -> 'sourceAddressPrefixes') > 0 then (sg -> 'properties' -> 'sourceAddressPrefixes')
            else jsonb_build_array(sg -> 'properties' -> 'sourceAddressPrefix')
          end) as sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Inbound'
        and sg -> 'properties' ->> 'protocol' in ('TCP','*')
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'Any', '<nw>/0', '/0')
        and (
          dport in ('22', '3389', '*')
          or (
            dport like '%-%'
            and (
              (
                split_part(dport, '-', 1) :: integer <= 3389
                and split_part(dport, '-', 2) :: integer >= 3389
              )
              or (
                split_part(dport, '-', 1) :: integer <= 22
                and split_part(dport, '-', 2) :: integer >= 22
              )
            )
          )
        )
    )
    select
      count(*) as value,
      'Unrestricted Remote Access' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine as vm
      left join network_sg as sg on vm.network_interfaces @> sg.network_interfaces
    where
      sg.sg_name is not null;
  EOQ
}

query "compute_virtual_machine_vulnerability_assessment_disabled_count" {
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
      count(*) as value,
      'Vulnerability Assessment Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_virtual_machine as a
      left join agent_installed_vm as b on a.vm_id = b.vm_id
    where
      b.vm_id is null;
  EOQ
}

# Assessment Queries

query "compute_virtual_machine_by_host_encryption_status" {
  sql = <<-EOQ
    select
      encryption,
      count(*)
    from (
      select security_profile -> 'encryptionAtHost',
        case when security_profile -> 'encryptionAtHost' <> 'true' or security_profile -> 'encryptionAtHost' is null then 'unencrypted'
        else 'encrypted'
        end encryption
      from
        azure_compute_virtual_machine) as vm
    group by
      encryption
    order by
      encryption;
  EOQ
}

query "compute_virtual_machine_by_public_ip" {
  sql = <<-EOQ
    with vm_visibility as (
      select
        case
          when public_ips is null then 'private'
          else 'public'
        end as visibility
      from
        azure_compute_virtual_machine
    )
    select
      visibility,
      count(*)
    from
      vm_visibility
    group by
      visibility
  EOQ
}

query "compute_virtual_machine_by_attachment_to_network" {
  sql = <<-EOQ
    with vm_with_network_interfaces as (
      select
        vm.id as vm_id,
        n ->> 'id' as network_id
      from
        azure_compute_virtual_machine as vm,
        jsonb_array_elements(network_interfaces) as n
    ),
    vm_with_appoved_networks as (
      select
        vn.vm_id as vm_id,
        vn.network_id as network_id,
        t.title as title
      from
        vm_with_network_interfaces as vn
        left join azure_network_interface as t on t.id = vn.network_id
      where exists (
        select
          ip -> 'properties' -> 'subnet' ->> 'id' as ip
        from
          azure_network_interface,
          jsonb_array_elements(ip_configurations) as ip
        where
          ip -> 'properties' -> 'subnet' ->> 'id' is not null
      )
    )
    select
      attachment,
      count(*)
    from (
      select b.vm_id,
        case when b.vm_id is null then
          'unattached'
        else
          'attached'
        end attachment
      from
        azure_compute_virtual_machine as a
        left join vm_with_appoved_networks as b on a.id = b.vm_id) as vm
    group by
      attachment
    order by
      attachment;
  EOQ
}

query "compute_virtual_machine_by_disaster_recovery_status" {
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
      status,
      count(*)
    from (
      select
        source_id,
        case when source_id is null then
          'disabled'
        else
          'enabled'
        end status
      from
        azure_compute_virtual_machine as vm
        left join vm_dr_enabled as l on lower(vm.id) = lower(l.source_id)) as vm
    group by
      status
    order by
      status;
  EOQ
}

query "compute_virtual_machine_by_remote_access" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name as sg_name,
        network_interfaces
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(security_rules) as sg,
        jsonb_array_elements_text(
          case
            when jsonb_array_length(sg -> 'properties' -> 'destinationPortRanges') > 0 then (sg -> 'properties' -> 'destinationPortRanges')
            else jsonb_build_array(sg -> 'properties' -> 'destinationPortRange')
          end ) as dport,
        jsonb_array_elements_text(
          case
            when jsonb_array_length(sg -> 'properties' -> 'sourceAddressPrefixes') > 0 then (sg -> 'properties' -> 'sourceAddressPrefixes')
            else jsonb_build_array(sg -> 'properties' -> 'sourceAddressPrefix')
          end) as sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Inbound'
        and sg -> 'properties' ->> 'protocol' in ('TCP','*')
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport in ('22', '3389', '*')
          or (
            dport like '%-%'
            and (
              (
                split_part(dport, '-', 1) :: integer <= 3389
                and split_part(dport, '-', 2) :: integer >= 3389
              )
              or (
                split_part(dport, '-', 1) :: integer <= 22
                and split_part(dport, '-', 2) :: integer >= 22
              )
            )
          )
        )
    )
    select
      status,
      count(*)
    from (
      select sg.sg_name,
        case when sg.sg_name is null then
          'restricted'
        else
          'unrestricted'
        end status
      from
        azure_compute_virtual_machine as vm
        left join network_sg as sg on vm.network_interfaces @> sg.network_interfaces ) as vm
    group by
      status
    order by
      status;
  EOQ
}

query "compute_virtual_machine_by_vulnerability_assessment_solution" {
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
      status,
      count(*)
    from (
      select b.vm_id,
        case when b.vm_id is not null then
          'enabled'
        else
          'disabled'
        end status
      from
        azure_compute_virtual_machine as a
        left join agent_installed_vm as b on a.vm_id = b.vm_id) as vm
    group by
      status
    order by
      status;
  EOQ
}

# Analysis Queries

query "compute_virtual_machine_by_subscription" {
  sql = <<-EOQ
    select
      a.title as "Subscription",
      count(v.*) as "VMs"
    from
      azure_compute_virtual_machine as v,
      azure_subscription as a
    where
      a.subscription_id = v.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "compute_virtual_machine_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(v.*) as "VMs"
    from
      azure_compute_virtual_machine as v,
      azure_subscription as sub
    where
      v.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "compute_virtual_machine_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "VMs"
    from
      azure_compute_virtual_machine
    group by
      region
    order by
      region;
  EOQ
}

query "compute_virtual_machine_by_os_type" {
  sql = <<-EOQ
    select
      os_type as "OS Type",
      count(os_type) as "VMs"
    from
      azure_compute_virtual_machine
    group by
      os_type
    order by
      os_type;
  EOQ
}

query "compute_virtual_machine_by_size" {
  sql = <<-EOQ
    select
      size as "Size",
      count(size) as "VMs"
    from
      azure_compute_virtual_machine
    group by
      size
    order by
      size;
  EOQ
}

query "compute_virtual_machine_top10_cpu_past_week" {
  sql = <<-EOQ
    with top_n as (
      select
        name,
        resource_group,
        avg(average)
      from
        azure_compute_virtual_machine_metric_cpu_utilization_daily
      where
        timestamp >= CURRENT_DATE - INTERVAL '7 day'
      group by
        name,
        resource_group
      order by
        avg desc
      limit 10
    )
    select
      timestamp,
      name,
      average
    from
      azure_compute_virtual_machine_metric_cpu_utilization_hourly
    where
      timestamp >= CURRENT_DATE - INTERVAL '7 day'
      and name in (select name from top_n group by name, resource_group)
    order by
      timestamp;
  EOQ
}

query "compute_virtual_machine_by_cpu_utilization_category" {
  sql = <<-EOQ
    with cpu_buckets as (
      select
        unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ]) as cpu_bucket
    ),
    max_averages as (
      select
        name,
        resource_group,
        case
          when max(average) <= 1 then 'Unused (<1%)'
          when max(average) between 1 and 10 then 'Underutilized (1-10%)'
          when max(average) between 10 and 90 then 'Right-sized (10-90%)'
          when max(average) > 90 then 'Overutilized (>90%)'
        end as cpu_bucket,
        max(average) as max_avg
      from
        azure_compute_virtual_machine_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        name, resource_group
    )
    select
      b.cpu_bucket as "CPU Utilization",
      count(a.*)
    from
      cpu_buckets as b
    left join max_averages as a on b.cpu_bucket = a.cpu_bucket
    group by
      b.cpu_bucket;
  EOQ
}
