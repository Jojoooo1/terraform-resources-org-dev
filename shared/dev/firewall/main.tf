
locals {
  network                           = data.terraform_remote_state.network.outputs.network_self_link
  gcp_private_service_access_ranges = data.terraform_remote_state.network.outputs.subnets_gcp_private_service_access_ranges

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Firewall Egress configuration
 *****************************************/

# Important: By default deny all egress traffic
resource "google_compute_firewall" "deny_all_egress" {
  project = var.project_id

  name    = "deny-all-egress"
  network = local.network

  deny {
    protocol = "all"
  }

  priority  = 65530
  direction = "EGRESS"

  destination_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_all_egress" {
  project = var.project_id

  name    = "allow-all-egress"
  network = local.network

  allow {
    protocol = "all"
  }

  priority  = 1000
  direction = "EGRESS"

  target_tags        = ["allow-all-egress"]
  destination_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_gcp_private_service_access_egress" {
  project = var.project_id

  name    = "allow-all-gcp-private-service-access-egress"
  network = local.network

  allow {
    protocol = "all"
  }

  priority  = 1000
  direction = "EGRESS"

  target_tags        = ["allow-gcp-private-service-access"]
  destination_ranges = [local.gcp_private_service_access_ranges]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

/******************************************
  Firewall Ingress configuration
 *****************************************/
resource "google_compute_firewall" "allow_ssh_from_iap_ingress" {
  project = var.project_id

  name    = "allow-ssh-from-iap-ingress"
  network = local.network


  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  priority  = 1000
  direction = "INGRESS"

  target_tags   = ["allow-ssh-from-iap"]
  source_ranges = ["35.235.240.0/20"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow internal ingress traffic within private subnet
# resource "google_compute_firewall" "allow_internal" {
#   project = var.project_id

#   name    = "allow-internal"
#   network = local.network


#   allow {
#     protocol = "all"
#   }

#   priority  = 1000
#   direction = "INGRESS"

#   target_tags   = ["allow-internal"]
#   source_ranges = ["10.0.32.0/19"]

#   log_config {
#     metadata = "INCLUDE_ALL_METADATA"
#   }
# }
