node "activedirectory_directory_role" {
  category = category.activedirectory_directory_role

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Role Template ID', role_template_id,
        'Description', description,
        'Display Name', display_name,
        'Tenant ID', tenant_id
      ) as properties
    from
      azuread_directory_role
    where
      id = any($1);
  EOQ

  param "activedirectory_directory_role_ids" {}
}

node "activedirectory_group" {
  category = category.activedirectory_group

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Security Enabled', security_enabled,
        'Visibility', visibility,
        'Display Name', display_name,
        'Tenant ID', tenant_id
      ) as properties
    from
      azuread_group
    where
      id = any($1);
  EOQ

  param "activedirectory_group_ids" {}
}

node "activedirectory_user" {
  category = category.activedirectory_user

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Display Name', display_name,
        'User Type', user_type,
        'ID', id,
        'Account_Enabled', account_enabled,
        'Tenant ID', tenant_id
      ) as properties
    from
      azuread_user
    where
      id = any($1);
  EOQ

  param "activedirectory_user_ids" {}
}

node "role_definition" {
  category = category.role_definition

  sql = <<-EOQ
    select
      d.id as id,
      d.title as title,
      jsonb_build_object(
        'ID', d.id,
        'Role Type', role_type,
        'Description', description,
        'Role Name', role_name,
        'Subscription ID', d.subscription_id
      ) as properties
    from
      azure_role_definition as d
      left join azure_subscription as s on s.subscription_id = d.subscription_id
    where
      d.id = any($1);
  EOQ

  param "role_definition_ids" {}
}