dashboard "azure_compute_snapshot_dashboard" {

  title         = "Azure Compute Snapshot Dashboard"
  documentation = file("./dashboards/compute/docs/compute_snapshot_dashboard.md")

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.azure_compute_snapshot_count
      width = 2
    }

    card {
      query = query.azure_compute_snapshot_storage_total
      width = 2
    }

    card {
      query = query.azure_compute_snapshot_unrestricted_network_access_count
      width = 2
    }

    card {
      query = query.azure_compute_snapshot_incremental_disabled_count
      width = 2
    }

    card {
      query = query.azure_compute_snapshot_encryption_setting_collection_disabled_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Network Access Status"
      query = query.azure_compute_snapshot_by_network_access_policy_status
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
      title = "Incremental Status"
      query = query.azure_compute_snapshot_incremental_status
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
      title = "Encryption Setting Collection Status"
      query = query.azure_compute_snapshot_encryption_setting_collection_status
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
      title = "Snapshots by Subscription"
      query = query.azure_compute_snapshot_by_subscription
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Resource Group"
      query = query.azure_compute_snapshot_by_resource_group
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Region"
      query = query.azure_compute_snapshot_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Encryption Type"
      query = query.azure_compute_snapshot_by_encryption_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by OS Type"
      query = query.azure_compute_snapshot_by_os_type
      type  = "column"
      width = 4
    }
  }

}

# Card Queries

query "azure_compute_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Snapshots" from azure_compute_snapshot;
  EOQ
}

query "azure_compute_snapshot_unrestricted_network_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unrestricted Network Access' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_snapshot
    where
      network_access_policy <> 'AllowPrivate';
  EOQ
}

query "azure_compute_snapshot_storage_total" {
  sql = <<-EOQ
    select
      sum(disk_size_gb) as "Total Storage (GB)"
    from
      azure_compute_snapshot;
  EOQ
}

query "azure_compute_snapshot_incremental_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Incremental Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_snapshot
    where
      incremental is not true;
  EOQ
}

# https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.compute.models.encryptionsettingscollection.-ctor?view=azure-dotnet
query "azure_compute_snapshot_encryption_setting_collection_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Encryption Setting Collection Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_snapshot
    where
      encryption_setting_collection_enabled is not true;
  EOQ
}

# Assessment Queries

query "azure_compute_snapshot_by_network_access_policy_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select network_access_policy,
        case
        when network_access_policy = 'AllowPrivate' then 'restricted'
        when network_access_policy = 'AllowAll' then 'unrestricted'
        else 'denied'
        end as status
      from
        azure_compute_snapshot) as cs
    group by
      status
    order by
      status;
  EOQ
}

query "azure_compute_snapshot_incremental_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select incremental,
        case
        when incremental then 'enabled' else 'disabled'
        end as status
      from
        azure_compute_snapshot) as cs
    group by
      status
    order by
      status;
  EOQ
}

query "azure_compute_snapshot_encryption_setting_collection_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select
        case
          when encryption_setting_collection_enabled then 'enabled' else 'disabled'
        end as status
      from
        azure_compute_snapshot) as cs
    group by
      status
    order by
      status;
  EOQ
}

# Analysis Queries

query "azure_compute_snapshot_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(s.*) as "Snapshots"
    from
      azure_compute_snapshot as s,
      azure_subscription as sub
    where
      sub.subscription_id = s.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "azure_compute_snapshot_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(s.*) as "Snapshots"
    from
      azure_compute_snapshot as s,
      azure_subscription as sub
    where
       s.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_compute_snapshot_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Snapshots"
    from
      azure_compute_snapshot
    group by
      region
    order by
      region;
  EOQ
}

query "azure_compute_snapshot_by_encryption_type" {
  sql = <<-EOQ
    select
      encryption_type as "Encryption Type",
      count(os_type) as "Snapshots"
    from
      azure_compute_snapshot
    group by
      encryption_type
    order by
      encryption_type;
  EOQ
}

query "azure_compute_snapshot_by_os_type" {
  sql = <<-EOQ
    select
      os_type as "OS Type",
      count(os_type) as "Snapshots"
    from
      azure_compute_snapshot
    group by
      os_type
    order by
      os_type;
  EOQ
}
