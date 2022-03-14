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
      sql   = query.azure_compute_snapshot_unencrypted_count.sql
      width = 2
    }

    card {
      sql   = query.azure_compute_snapshot_public_network_access_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Encryption Status"
      sql   = query.azure_compute_snapshot_by_encryption_status.sql
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
      title = "Network Access Policy Status"
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
  }

}

# Card Queries

query "azure_compute_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Snapshots" from azure_compute_snapshot;
  EOQ
}

query "azure_compute_snapshot_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_snapshot
    where
      encryption_type not in
        ('EncryptionAtRestWithPlatformKey', 'EncryptionAtRestWithCustomerKey', 'EncryptionAtRestWithPlatformAndCustomerKeys');
  EOQ
}

query "azure_compute_snapshot_public_network_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public NetWork Access' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_compute_snapshot
    where
      network_access_policy <> 'AllowPrivate';
  EOQ
}

# Assessment Queries

query "azure_compute_snapshot_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption,
      count(*)
    from (
      select encryption_type,
        case when encryption_type in
          ('EncryptionAtRestWithPlatformKey', 'EncryptionAtRestWithCustomerKey', 'EncryptionAtRestWithPlatformAndCustomerKeys')
        then
          'encrypted'
        else
          'unencrypted'
        end encryption
      from
        azure_compute_snapshot) as cd
    group by
      encryption
    order by
      encryption;
  EOQ
}

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
