#########
# Service Account Creation
#########

# Service account creation
resource "google_service_account" "tf_service_account" {
  #checkov:skip=CKV2_GCP_3:We will not have any service account keys
  project      = var.gcp_project_id
  account_id   = var.sa_name
  display_name = var.sa_name
  description  = var.sa_description
}

# Build service account IAM policy for impersonators
data "google_iam_policy" "tf_service_account_iam_policy" {
  dynamic "binding" {
    for_each = var.impersonate_roles
    content {
      role    = binding.value
      members = local.impersonator_group_emails
    }
  }
}

# Apply the service account IAM policy
resource "google_service_account_iam_policy" "tf_service_account_iam_policy" {
  service_account_id = google_service_account.tf_service_account.name
  policy_data        = data.google_iam_policy.tf_service_account_iam_policy.policy_data
}

#########
# Service Account Project Access
#########

resource "google_project_iam_member" "tf_service_account_project_role" {
  for_each = toset(local.project_roles)
  project  = var.gcp_project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.tf_service_account.email}"
}

#########
# Service Account Identity Group Membership
#########
resource "google_cloud_identity_group_membership" "tf_group_membership" {
  for_each = toset(var.sa_groups)
  group    = each.value

  preferred_member_key {
    id = google_service_account.tf_service_account.email
  }

  roles {
    name = "MEMBER"
  }
}


#########
# State Bucket Creation
#########

# GCS Bucket Creation
resource "google_storage_bucket" "tf_state_gcs" {
  #checkov:skip=CKV_GCP_5:Bucket is encrypted with default GCP keys
  #checkov:skip=CKV_GCP_29:Checkov is not detecting the uniform bucket level access correctly
  #checkov:skip=CKV_GCP_62:TODO Add bucket access logging
  name                        = var.bucket_name
  project                     = var.gcp_project_id
  location                    = var.bucket_location
  storage_class               = var.bucket_storage_class
  uniform_bucket_level_access = true # Hardcoding this as we don't want to use legacy ACLs
  labels                      = local.bucket_labels

  versioning {
    enabled = true # Hardcoding as we want to make sure versioning is forced.
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age                = var.bucket_obj_lifecycle_age
      num_newer_versions = var.bucket_obj_lifecycle_newer_versions
    }
  }
}

# Build bucket IAM policy for bucket access
# Only allow the terraform service account direct access to the bucket and objects
data "google_iam_policy" "tf_state_gcs_bucket_policy" {
  dynamic "binding" {
    for_each = var.bucket_state_access_roles
    content {
      role    = binding.value
      members = ["serviceAccount:${google_service_account.tf_service_account.email}"]
    }
  }
}

# Apply bucket IAM policy
resource "google_storage_bucket_iam_policy" "tf_state_gcs_bucket_policy" {
  bucket      = google_storage_bucket.tf_state_gcs.name
  policy_data = data.google_iam_policy.tf_state_gcs_bucket_policy.policy_data
}
