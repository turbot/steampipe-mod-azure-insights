node "kubernetes_cluster" {
  category = category.kubernetes_cluster

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', lower(id),
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Provisioning State', provisioning_state,
        'Type', type,
        'Kubernetes Version', kubernetes_version,
        'Region', region
      ) as properties
    from
      azure_kubernetes_cluster
      join unnest($1::text[]) as i on lower(id) = i and subscription_id = split_part(i, '/', 3);
  EOQ

  param "kubernetes_cluster_ids" {}
}

node "kubernetes_node_pool" {
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
      azure_kubernetes_cluster c
      join unnest($1::text[]) as i on lower(id) = i and subscription_id = split_part(i, '/', 3),
      jsonb_array_elements(agent_pool_profiles) p;
  EOQ

  param "kubernetes_cluster_ids" {}
}