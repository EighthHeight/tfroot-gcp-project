#########
# General
#########

variable "gcp_project_id" {
  type        = string
  description = "ID of the project to create the terraform resources in"
}

#########
# Service Account
#########

variable "sa_name" {
  type        = string
  description = "Name of the terraform service account for this project"
  default     = "terraform"
}

variable "sa_description" {
  type        = string
  description = "Description of the terraform service account"
  default     = "Terraform execution service account used by any/all terraform managment of resources in this project"
}

variable "project_roles" {
  type        = list(string)
  description = "List of roles teraform needs to operate in this project"
  default     = []
}

locals {
  project_roles_enforced = [
    "roles/iam.serviceAccountAdmin",
    "roles/monitoring.alertPolicyEditor",
    "roles/monitoring.notificationChannelEditor",
    "roles/pubsub.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/storage.admin",
  ]
  project_roles = distinct(concat(local.project_roles_enforced, var.project_roles))
}

# Right now we only do groups, but we can add users or service accounts later if needed
variable "impersonator_group_emails" {
  type        = list(string)
  description = "List of group email addresses which are allowed to impersonate the terraform service account."
}

locals {
  impersonator_group_emails = [
    for group_email in var.impersonator_group_emails :
    "group:${group_email}"
  ]
}

variable "impersonate_roles" {
  type        = list(string)
  description = "List of roles requires on the service account in order to impersonate it."
  default = [
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.workloadIdentityUser",
  ]
}

#########
# Cloud identity terraform service account groups
# Adds created terraform service account to an existing workspace group.
#########

variable "sa_groups" {
  type        = list(string)
  description = "ID of the group which the terraform service account will be added as a member"
  default     = []
}

#########
# State Bucket
#########

variable "bucket_name" {
  type        = string
  description = "Name of the terraform state bucket"
  default     = "tfstate"
}

variable "bucket_location" {
  type        = string
  description = "GCS location"
  default     = "US"
}

variable "bucket_storage_class" {
  type        = string
  description = "Storage class of the bucket"
  default     = "MULTI_REGIONAL"
}

variable "bucket_labels" {
  type        = map(string)
  description = "Labels which will be added to the enforced labels"
  default     = {}
}

locals {
  bucket_labels_enforced = {
    heritage = "terraform"
    usage    = "project-terraform-state"
  }

  bucket_labels = merge(var.bucket_labels, local.bucket_labels_enforced)
}

variable "bucket_obj_lifecycle_age" {
  type        = number
  description = "The age in days that a version of a object is eligible for deletion"
  default     = 14
}

variable "bucket_obj_lifecycle_newer_versions" {
  type        = number
  description = "The number of newer versions of an object before a version is eligible for deletion"
  default     = 5
}

variable "bucket_state_access_roles" {
  type        = list(string)
  description = "List of the roles required to create and update the terraform state object"
  default = [
    "roles/storage.objectAdmin",
  ]
}
