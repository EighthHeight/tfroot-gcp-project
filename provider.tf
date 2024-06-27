terraform {
  required_version = "~> 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.31.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
  }
}

##########
# Providers
##########
provider "google" {
  project                     = var.gcp_project_id
  region                      = var.provider_gcp_region
  impersonate_service_account = var.terraform_sa_email
}
