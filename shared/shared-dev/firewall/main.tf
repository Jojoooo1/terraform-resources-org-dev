
/******************************************
  Firewall Egress configuration
 *****************************************/

# Important: By default deny all egress traffic
resource "google_compute_firewall" "deny-all-egress" {
  project = var.project_id

  name    = "default-deny-all-egress"
  network = local.network

  deny {
    protocol = "all"
  }

  direction          = "EGRESS"
  priority           = 65530
  destination_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow-all-egress" {
  project = var.project_id

  name    = "allow-all-egress"
  network = local.network

  allow {
    protocol = "all"
  }

  direction          = "EGRESS"
  priority           = 1000
  target_tags        = ["allow-all-egress"]
  destination_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow-private-service-access" {
  project = var.project_id

  name    = "allow-private-service-access-egress"
  network = local.network

  allow {
    protocol = "all"
  }

  direction          = "EGRESS"
  priority           = 1000
  target_tags        = ["allow-private-service-access"]
  destination_ranges = [local.private_service_connect_cidr]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# can add egress to internal private subnet if necessary

/******************************************
  Firewall Ingress configuration
 *****************************************/
resource "google_compute_firewall" "allow-bastion-iap" {
  project = var.project_id

  name    = "allow-bastion-iap-ingress-tcp-22"
  network = local.network


  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  priority      = 1000
  target_tags   = ["allow-iap"]
  source_ranges = ["35.235.240.0/20"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

