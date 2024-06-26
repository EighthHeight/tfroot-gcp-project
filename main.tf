#########
# Lookup the folder id references
#########
data "terraform_remote_state" "org_state" {
  backend = "gcs"
  config = {
    bucket                      = var.org_state_bucket
    prefix                      = var.org_state_prefix
    impersonate_service_account = var.terraform_sa_email
  }
}

locals {
  parent_folder_id = data.terraform_remote_state.org_state.outputs.org_folders[var.org_folder_refid].folder_id
}


#########
# Generate a random project ID
#########
module "project_id_generator" {
  source = "./modules/project-id-generator"
}


#########
# Project Creation
#########
module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 15.0.1"

  billing_account         = var.billing_account_id
  default_service_account = var.default_service_account_state
  activate_apis           = local.activate_apis
  activate_api_identities = local.activate_api_identities
  folder_id               = local.parent_folder_id
  labels                  = var.project_labels
  name                    = var.project_name
  org_id                  = var.gcp_org_id
  project_id              = var.project_id != null ? var.project_id : module.project_id_generator.project_id
  random_project_id       = false # Using our own random project id generator
  create_project_sa       = false # We will be managing our service acccounts seperatly
  # VPC networks
  grant_network_role = false
}

#########
# Project Managment IAM Configuration
# This tightly managed the `Owner` role and sets the admin for least privilage
#########
module "management-iam" {
  source         = "./modules/project-management-iam"
  gcp_project_id = module.project-factory.project_id

  org_admin_sa_email = var.terraform_sa_email
  org_admin_sa_roles = var.org_admin_sa_roles
  owners             = var.project_owners
}


#########
# API Service Account Groups
#########
locals {
  api_identity_group_list = flatten([
    for api in local.activate_api_identities : [
      for group in api.groups : {
        sa_email = lookup(module.project-factory.enabled_api_identities, api.api, null)
        group    = group
      }
    ]
  ])

  api_identity_group_map = {
    for identity in local.api_identity_group_list :
    "${identity.sa_email}-${identity.group}" => identity
  }
}

module "api-sa-groups" {
  source   = "./modules/project-api-sa-group-membership"
  for_each = local.api_identity_group_map

  sa_email = each.value.sa_email
  group_id = each.value.group
}


#########
# Terraform CM (SA and Bucket)
#########
module "terraform-access" {
  source         = "./modules/project-terraform-access"
  gcp_project_id = module.project-factory.project_id
  depends_on     = [module.management-iam]

  sa_name                   = var.tfsa_name
  project_roles             = var.tfsa_project_roles
  impersonator_group_emails = var.tfsa_impersonator_group_emails
  sa_groups                 = var.tfsa_groups
  bucket_name               = "${var.tfbucket_name_prefix}--${module.project-factory.project_id}"
}


#########
# Group IAM access to project
#########
locals {
  group_roles_list = distinct(flatten([
    for group in var.group_iam_access :
    group.roles
  ]))
  group_role_bindings = {
    for role in local.group_roles_list :
    role => [
      for group in var.group_iam_access :
      "group:${group.group_email}"
      if contains(group.roles, role)
    ]
  }
}

module "group-iam-access" {
  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "7.7.1"

  projects = [module.project-factory.project_id]
  bindings = local.group_role_bindings
}
