terraform {
  required_version = ">= 1.5.7"

  backend "gcs" {
    bucket = "tf-state-30994"
    prefix = "terraform/state/iap"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.1.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.1.0"
    }
  }
}
