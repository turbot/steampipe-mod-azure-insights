edge "kubernetes_cluster_to_compute_disk_encryption_set" {
  title = "disk encryption set"

  sql = <<-EOQ
    select
      lower(c.id) as from_id,
      lower(e.id) as to_id
    from
      azure_kubernetes_cluster c
      join unnest($1::text[]) as i on lower(c.id) = i and c.subscription_id = split_part(i, '/', 3),
      azure_compute_disk_encryption_set e
    where
      lower(c.disk_encryption_set_id) = lower(e.id);
  EOQ

  param "kubernetes_cluster_ids" {}
}

edge "kubernetes_cluster_to_compute_virtual_machine_scale_set" {
  title = "vm scale set"

  sql = <<-EOQ
    select
      lower(c.id) as from_id,
      lower(set.id) as to_id
    from
      azure_kubernetes_cluster c
      join unnest($1::text[]) as i on lower(c.id) = i and c.subscription_id = split_part(i, '/', 3),
      azure_compute_virtual_machine_scale_set set
    where
      lower(set.resource_group) = lower(c.node_resource_group);
  EOQ

  param "kubernetes_cluster_ids" {}
}

edge "kubernetes_cluster_to_compute_virtual_machine_scale_set_vm" {
  title = "instance"

  sql = <<-EOQ
    select
      lower(set.id) as from_id,
      lower(vm.id) as to_id
    from
      azure_kubernetes_cluster c
      join unnest($1::text[]) as i on lower(c.id) = i and c.subscription_id = split_part(i, '/', 3),
      azure_compute_virtual_machine_scale_set set,
      azure_compute_virtual_machine_scale_set_vm vm
    where
      lower(set.resource_group) = lower(c.node_resource_group)
      and set.name = vm.scale_set_name
      and vm.resource_group = set.resource_group;
  EOQ

  param "kubernetes_cluster_ids" {}
}

edge "kubernetes_cluster_to_kubernetes_node_pool" {
  title = "node pool"

  sql = <<-EOQ
    select
      lower(c.id) as from_id,
      p ->> 'name' as to_id
    from
      azure_kubernetes_cluster c
      join unnest($1::text[]) as i on lower(c.id) = i and c.subscription_id = split_part(i, '/', 3),
      jsonb_array_elements(agent_pool_profiles) p;
  EOQ

  param "kubernetes_cluster_ids" {}
}
