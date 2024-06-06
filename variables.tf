##########
# Provider variables/data
##########
variable "gcp_org_id" {
  type        = string
  description = "GCP organization ID"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID for org-seed"
}

variable "terraform_sa_email" {
  type        = string
  description = "Email address for the service account terraform will run under"
}

variable "provider_gcp_region" {
  type        = string
  description = "Default region used by the provider"
  default     = "us-west1"
}

#########
# Existing Infrastructure
#########
variable "org_state_bucket" {
  type        = string
  description = "The bucket name which holds the organization state"
}

variable "org_state_prefix" {
  type        = string
  description = "Prefix of the the organization config state"
  default     = "gcp-organization"
}

variable "org_folder_refid" {
  type        = string
  description = <<EOT
    Terraform reference ID of the parent folder.
    This is referenced against the organization terraform root config.
  EOT
}


#########
# Org Info
#########
variable "billing_account_id" {
  type        = string
  description = "ID of the billing account to associate the project to"
}


#########
# Project
#########
variable "project_name" {
  type        = string
  description = "Readable name of the host project"
}

variable "project_id" {
  type        = string
  description = <<EOT
    Manual setting of the project ID.
    If this is not set a random project ID will be generated and used. Project IDs are immutible, so do not set this project ID unless you want this ID for all time.
  EOT
  default     = null
}

variable "project_labels" {
  type        = map(string)
  description = "Labels to add to the project beyond the enforced labels"
  default     = {}
}

variable "default_service_account_state" {
  type        = string
  description = "State of the defalt service accounts when the project is created."
  default     = "disable"
}

variable "project_owners" {
  type        = list(string)
  description = <<EOT
    Users, Service Acccounts, and/or groups which have owner access to the project.
    **DO NOT** use this variable if it is not needed. This level of access is way beyond least previledge.
  EOT
  default     = []
}

variable "org_admin_sa_roles" {
  type = list(string)
  description = "List of roles which the admin service account will retain within the created project"
  default = []
}

#########
# Project APIs
#########
variable "activate_apis" {
  type        = list(string)
  description = "List of the apis which should be activated for this project"
  default     = []
}

variable "activate_apis_enforced" {
  type        = list(string)
  description = "List of the apis which all projects, created with this module, will have active by default"
  default = [
    "certificatemanager.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "secretmanager.googleapis.com",
    "servicecontrol.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
  ]
}

variable "activate_api_identities" {
  type = list(object({
    api    = string
    roles  = list(string)
    groups = optional(list(string), [])
  }))
  description = "List of the apis which all projects will have active by defaut and the service identities will also be created on project spin-up"
  default     = []
}

variable "activate_api_identities_enforced" {
  type = list(object({
    api    = string
    roles  = list(string)
    groups = optional(list(string), [])
  }))
  description = "List of the apis which all projects will have active by defaut and the service identities will also be created on project spin-up"
  default = [
    {
      api   = "cloudbuild.googleapis.com"
      roles = []
    },
    {
      api   = "storage.googleapis.com"
      roles = []
    }
  ]
}

locals {
  activate_apis = distinct(concat(
    var.activate_apis,
    var.activate_apis_enforced,
  ))

  activate_api_identities = distinct(concat(
    var.activate_api_identities,
    var.activate_api_identities_enforced,
  ))
}

#########
# Terraform Service Account
#########
variable "tfsa_name" {
  type        = string
  description = "Name of the terraform service account for this project"
  default     = "terraform"
}

variable "tfsa_project_roles" {
  type        = list(string)
  description = "List of roles terraform needs to operate in this project"
  default     = []
}

variable "tfsa_impersonator_group_emails" {
  type        = list(string)
  description = "List of user/group email addresses which are allowed to impersonate the terraform service account."
  default = []
}

variable "tfsa_groups" {
  type        = list(string)
  description = "ID of the group which the terraform service account will be added as a member"
  default     = []
}

#########
# Terraform State Bucket
#########
variable "tfbucket_name_prefix" {
  type        = string
  description = <<EOT
    The project terraform state bucket name prefix.
    The full bucket name will be `name_prefix`-`project_id`
  EOT
  default     = "tfstate"
}
