node "kubernetes_cluster" {
  category = category.kubernetes_cluster

  sql = <<-EOQ
    select
      lower(id),
      title,
      jsonb_build_object(
        'ID', ID,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Provisioning State', provisioning_state,
        'Type', type,
        'Kubernetes Version', kubernetes_version,
        'Region', region
      ) as properties
    from
      azure_kubernetes_cluster
    where
      lower(id) = any($1);
  EOQ

  param "kubernetes_cluster_ids" {}
}

node "kubernetes_cluster_kubernetes_node_pool" {
  category = category.kubernetes_node_pool

  sql = <<-EOQ
    select
      p ->> 'name' as id,
      p ->> 'name' as title,
      jsonb_build_object(
        'Name', p ->> 'name',
        'Node Count', p ->> 'count',
        'Autoscaling Enabled' , p ->> 'enableAutoScaling',
        'Is Public', p ->> 'enableNodePublicIP',
        'OS Disk Size(GB)', p ->> 'osDiskSizeGB',
        'OS Disk Type', p ->> 'osDiskType',
        'OS Disk Type', p ->> 'osDiskType',
        'OS Type', p ->> 'osType',
        'VM Size', p ->> 'vmSize'
      ) as properties
    from
      azure_kubernetes_cluster c,
      jsonb_array_elements(agent_pool_profiles) p
    where
      lower(c.id) = any($1);
  EOQ

  param "kubernetes_cluster_ids" {}
}

node "kubernetes_cluster_compute_disk_encryption_set" {
  category = category.compute_disk_encryption_set

  sql = <<-EOQ
    select
      lower(e.id) as id,
      e.title as title,
      jsonb_build_object(
        'Name', e.name,
        'ID', e.id,
        'Subscription ID', e.subscription_id,
        'Resource Group', e.resource_group,
        'Region', e.region
      ) as properties
    from
      azure_kubernetes_cluster c,
      azure_compute_disk_encryption_set e
    where
      lower(c.disk_encryption_set_id) = lower(e.id)
      and lower(c.id) = any($1);
  EOQ

  param "kubernetes_cluster_ids" {}
}
