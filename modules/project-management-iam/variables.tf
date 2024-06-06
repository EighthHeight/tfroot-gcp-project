#########
# General
#########

variable "gcp_project_id" {
  type        = string
  description = "ID of the project to create the terraform resources in"
}

variable "owners" {
  type        = list(string)
  description = "Resource name of user/group/sa which can be owners of this project (ideally none)"
  default     = []
}

#########
# Permissions retained by the org admin project creator
#########
variable "org_admin_sa_email" {
  type        = string
  description = "Service account email which this terraform config is being run as"
}

variable "org_admin_sa_roles" {
  type        = list(string)
  description = "List of roles which the admin service account will retain within the created project"
  default = [
    # "roles/compute.instanceAdmin.v1",
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    # "roles/dns.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    # "roles/secretmanager.admin",
    # "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
    "roles/monitoring.admin",
    # "roles/certificatemanager.owner",
  ]
}
