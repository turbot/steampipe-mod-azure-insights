dashboard "azure_compute_snapshot_dashboard" {

  title = "Azure Compute Snapshot Dashboard"

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.azure_compute_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_snapshot_storage_total.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_snapshot_public_network_access_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_snapshot_incremental_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_snapshot_encryption_setting_collection_disabled_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Public/Private Status"
      sql   = query.azure_compute_snapshot_by_network_access_policy_status.sql
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
      title = "Incremental Status"
      sql   = query.azure_compute_snapshot_incremental_status.sql
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
      sql   = query.azure_compute_snapshot_encryption_setting_collection_status.sql
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
      sql   = query.azure_compute_snapshot_by_subscription.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Resource Group"
      sql   = query.azure_compute_snapshot_by_resource_group.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Region"
      sql   = query.azure_compute_snapshot_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Encryption Type"
      sql   = query.azure_compute_snapshot_by_encryption_type.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by OS Type"
      sql   = query.azure_compute_snapshot_by_os_type.sql
      type  = "column"
      width = 3
    }
  }

}

# Card Queries

query "azure_compute_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Snapshots" from azure_compute_snapshot;
  EOQ
}

query "azure_compute_snapshot_public_network_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
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
      not incremental;
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
      encryption_setting_collection_enabled <> true or encryption_setting_collection_enabled is null;
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
        when network_access_policy = 'AllowPrivate' then 'private'
        when network_access_policy = 'AllowAll' then 'public'
        else 'denied'
        end as status
      from
        azure_compute_snapshot) as cd
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
        azure_compute_snapshot) as cd
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
      select incremental,
        case
        when encryption_setting_collection_enabled then 'enabled' else 'disabled'
        end as status
      from
        azure_compute_snapshot) as cd
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
      a.title as "Subscription",
      count(v.*) as "Snapshots"
    from
      azure_compute_snapshot as v,
      azure_subscription as a
    where
      a.subscription_id = v.subscription_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "azure_compute_snapshot_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group as "Resource Group",
      count(resource_group) as "Snapshots"
    from
      azure_compute_snapshot
    group by
      resource_group
    order by
      resource_group;
  EOQ
}

query "azure_compute_snapshot_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Snapshots" from azure_compute_snapshot group by region order by region;
  EOQ
}

query "azure_compute_snapshot_by_encryption_type" {
  sql = <<-EOQ
    select
      encryption_type as "Type",
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
      os_type as "Type",
      count(os_type) as "Snapshots"
    from
      azure_compute_snapshot
    group by
      os_type
    order by
      os_type;
  EOQ
}
