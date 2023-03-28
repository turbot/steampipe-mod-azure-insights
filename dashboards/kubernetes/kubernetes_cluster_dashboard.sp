dashboard "kubernetes_cluster_dashboard" {

  title         = "Azure Kubernetes Cluster Dashboard"
  documentation = file("./dashboards/kubernetes/docs/kubernetes_cluster_dashboard.md")

  tags = merge(local.kubernetes_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.kubernetes_cluster_count
      width = 2
    }

    card {
      query = query.kubernetes_cluster_disk_unencrypted_count
      width = 2
    }

    card {
      query = query.kubernetes_cluster_public_access_disabled_count
      width = 2
    }

    card {
      query = query.kubernetes_cluster_rbac_disabled_count
      width = 2
    }

    card {
      query = query.kubernetes_cluster_pod_security_policy_disabled_count
      width = 2
    }

    card {
      query = query.kubernetes_cluster_auto_scaler_profile_disabled_count
      width = 2
    }
  }

  container {

    title = "Assessments"

    chart {
      title = "Disk Encryption Status"
      query = query.kubernetes_cluster_disk_by_encryption_status
      type  = "donut"
      width = 4

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
      title = "Public/Private Status"
      query = query.kubernetes_cluster_disk_public_status
      type  = "donut"
      width = 4

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
      title = "Role-Based Access"
      query = query.kubernetes_cluster_rbac_status
      type  = "donut"
      width = 4

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
      title = "Pod Security Policy"
      query = query.kubernetes_cluster_pod_security_policy_status
      type  = "donut"
      width = 4

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
      title = "Auto Scaling"
      query = query.kubernetes_cluster_auto_scaler_profile_status
      type  = "donut"
      width = 4

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
      title = "Clusters by Kubernetes Version"
      query = query.kubernetes_cluster_by_kubernetes_version
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by SKU"
      query = query.kubernetes_cluster_by_sku_name
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Subscription"
      query = query.kubernetes_cluster_by_subscription
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Resource Group"
      query = query.kubernetes_cluster_by_resource_group
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Region"
      query = query.kubernetes_cluster_by_region
      type  = "column"
      width = 4
    }
  }

}

# Card Queries

query "kubernetes_cluster_count" {
  sql = <<-EOQ
    select
      count(*) as "Clusters"
    from
      azure_kubernetes_cluster;
  EOQ
}

query "kubernetes_cluster_disk_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Disk Encryption Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_kubernetes_cluster
    where
      disk_encryption_set_id is null;
  EOQ
}

query "kubernetes_cluster_public_access_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_kubernetes_cluster
    where
      api_server_access_profile ->> 'authorizedIPRanges' is null
      and api_server_access_profile ->> 'enablePrivateCluster' = 'false';
  EOQ
}

query "kubernetes_cluster_rbac_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Role-Based Access Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_kubernetes_cluster
    where
      enable_rbac is null
      or not enable_rbac;
  EOQ
}

query "kubernetes_cluster_pod_security_policy_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Pod Security Policy Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_kubernetes_cluster
    where
      enable_pod_security_policy is null
      or not enable_pod_security_policy;
  EOQ
}

query "kubernetes_cluster_auto_scaler_profile_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Auto Scaling Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      azure_kubernetes_cluster
    where
      auto_scaler_profile is null;
  EOQ
}

# Assessment Queries

query "kubernetes_cluster_disk_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption,
      count(*)
    from (
      select
        case when disk_encryption_set_id is null then 'disabled'
        else 'enabled'
        end encryption
      from
        azure_kubernetes_cluster) as s
    group by
      encryption
    order by
      encryption;
  EOQ
}

query "kubernetes_cluster_disk_public_status" {
  sql = <<-EOQ
    select
      access,
      count(*)
    from (
      select
        case when api_server_access_profile ->> 'authorizedIPRanges' is null
          and api_server_access_profile ->> 'enablePrivateCluster' = 'false' then 'public'
        else 'private'
        end access
      from
        azure_kubernetes_cluster) as s
    group by
      access
    order by
      access;
  EOQ
}

query "kubernetes_cluster_rbac_status" {
  sql = <<-EOQ
    select
      rbac,
      count(*)
    from (
      select
        case when enable_rbac is null
          or not enable_rbac then 'disabled'
        else 'enabled'
        end rbac
      from
        azure_kubernetes_cluster) as s
    group by
      rbac
    order by
      rbac;
  EOQ
}

query "kubernetes_cluster_pod_security_policy_status" {
  sql = <<-EOQ
    select
      policy,
      count(*)
    from (
      select
        case when enable_pod_security_policy is null
          or not enable_pod_security_policy then 'disabled'
        else 'enabled'
        end policy
      from
        azure_kubernetes_cluster) as s
    group by
      policy
    order by
      policy;
  EOQ
}

query "kubernetes_cluster_auto_scaler_profile_status" {
  sql = <<-EOQ
    select
      auto_scaling,
      count(*)
    from (
      select
        case when auto_scaler_profile is null then 'disabled'
        else 'enabled'
        end auto_scaling
      from
        azure_kubernetes_cluster) as s
    group by
      auto_scaling
    order by
      auto_scaling;
  EOQ
}

# Analysis Queries

query "kubernetes_cluster_by_kubernetes_version" {
  sql = <<-EOQ
    select
      kubernetes_version as "Version",
      count(*) as "Clusters"
    from
      azure_kubernetes_cluster
    group by
      kubernetes_version
    order by
      kubernetes_version;
  EOQ
}

query "kubernetes_cluster_by_sku_name" {
  sql = <<-EOQ
    select
      (sku ->> 'name') || ' ' || (sku ->> 'tier') as "SKU",
      count(*) as "Clusters"
    from
      azure_kubernetes_cluster
    group by
      "SKU"
    order by
      "SKU";
  EOQ
}

query "kubernetes_cluster_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(s.*) as "Clusters"
    from
      azure_kubernetes_cluster as s,
      azure_subscription as sub
    where
      sub.subscription_id = s.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "kubernetes_cluster_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(s.*) as "Clusters"
    from
      azure_kubernetes_cluster as s,
      azure_subscription as sub
    where
       s.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "kubernetes_cluster_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Clusters"
    from
      azure_kubernetes_cluster
    group by
      region
    order by
      region;
  EOQ
}
