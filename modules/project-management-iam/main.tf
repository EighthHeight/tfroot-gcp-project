########
# Org Admin Permissions
########
resource "google_project_iam_member" "admin_sa_member" {
  for_each = toset(var.org_admin_sa_roles)

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${var.org_admin_sa_email}"
}

########
# Manage the owners of the new project
# This removes the terraform org admin as the owner (project creator)
########
resource "google_project_iam_binding" "project" {
  #checkov:skip=CKV_GCP_49:This is acctually removing the owner role
  project = var.gcp_project_id
  role    = "roles/owner"
  members = var.owners
  depends_on = [
    google_project_iam_member.admin_sa_member, #Ensure that owner is not removed until after the new roles are added
  ]
}

# Setup the owners (if any) as storage admins
resource "google_project_iam_member" "owner_gcs_access" {
  for_each = toset(var.owners)

  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = each.value
}
