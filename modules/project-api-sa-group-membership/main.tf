#########
# Service Account Identity Group Membership
#########
resource "google_cloud_identity_group_membership" "tf_group_membership" {
  group = var.group_id

  preferred_member_key {
    id = var.sa_email
  }

  roles {
    name = "MEMBER"
  }
}
