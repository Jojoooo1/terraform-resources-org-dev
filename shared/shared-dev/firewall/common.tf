terraform {
  required_version = ">= 1.5.7"

  backend "gcs" {
    bucket = "tf-state-16958"
    prefix = "terraform/state/firewall"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.83"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.83"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = "tf-state-16958"
    prefix = "terraform/state/network"
  }
}
