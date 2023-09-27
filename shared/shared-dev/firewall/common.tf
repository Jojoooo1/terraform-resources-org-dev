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

locals {
  network                      = data.terraform_remote_state.network.outputs.network_self_link
  private_service_connect_cidr = data.terraform_remote_state.network.outputs.subnets_private_service_access

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}
