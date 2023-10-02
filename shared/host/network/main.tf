
# Sources:
# terraform-google-cloud-router: https://github.com/terraform-google-modules/terraform-google-cloud-router/blob/master/examples/nat/vpc.tf
# terraform-google-project-factory: https://github.com/terraform-google-modules/terraform-google-project-factory/tree/v14.3.0/examples/shared_vpc
# terraform-example-foundation: https://github.com/terraform-google-modules/terraform-example-foundation/tree/master/3-networks-dual-svpc/modules/base_shared_vpc
# https://cloud.google.com/architecture/security-foundations
# https://cloud.google.com/architecture/best-practices-vpc-design

locals {

  vpc_name = "cl-dpl-vpc-dev"

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Shared VPC configuration
 *****************************************/
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "7.3"

  project_id   = var.project_id
  network_name = local.vpc_name

  shared_vpc_host                        = "true"
  delete_default_internet_gateway_routes = "true"
  routing_mode                           = "GLOBAL"

  subnets = var.subnets

  # Google Cloud security foundations guide v3: page 63
  # Some use cases, such as container-based workloads, can require additional aggregates. These need to be defined as subnet secondary ranges. 
  # For these cases, you can use address ranges that are taken from the reserved RFC 6598 (Shared Address Space address range 100.64.0.0/10 -> 100.64.0.0 until 100.127.255.255).
  secondary_ranges = var.secondary_ranges

  routes = [
    {
      name              = "rt-${local.vpc_name}-1000-egress-internet-default"
      description       = "Tag based route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      # Uncomment if you want to allow egress connectivity using tag based routing
      # tags              = "allow-igw"
      next_hop_internet = "true"
      priority          = "1000"
    }
  ]

}

/******************************************
  NAT Cloud Router & NAT config
 *****************************************/
resource "google_compute_router" "vpc_router" {
  project = var.project_id

  name    = "${local.vpc_name}-${var.region}-nat-router"
  region  = var.region
  network = module.vpc.network_self_link
}

resource "google_compute_address" "vpc_nat_ip" {
  project = var.project_id

  name   = "${local.vpc_name}-${var.region}-egress-nat-ip"
  region = var.region
}

resource "google_compute_router_nat" "vpc_nat" {
  project = var.project_id

  name   = "${local.vpc_name}-${var.region}-egress-nat"
  region = var.region
  router = google_compute_router.vpc_router.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.vpc_nat_ip.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = module.vpc.subnets["us-east1/cl-dpl-us-east1-dev-public"].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = module.vpc.subnets["us-east1/cl-dpl-us-east1-dev-private"].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    filter = "TRANSLATIONS_ONLY"
    enable = true
  }
}


/***************************************************************
  Configure Private Networking for GCP Services like Cloud SQL [...]
 **************************************************************/
resource "google_compute_global_address" "gcp_private_service_access_address" {
  project = var.project_id

  name    = "${local.vpc_name}-peering-gcp-private-service-access"
  network = module.vpc.network_self_link

  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  address       = "10.100.0.0"
  prefix_length = 16
}

# gcp_private_service_access_connection
resource "google_service_networking_connection" "gcp_private_vpc_connection" {
  network = module.vpc.network_self_link
  service = "servicenetworking.googleapis.com"

  reserved_peering_ranges = [google_compute_global_address.gcp_private_service_access_address.name]
}


# /***************************************************************
#   Configure Private Networking for GKE Master
#  **************************************************************/
# resource "google_compute_global_address" "gke_test_private_master_address" {
#   project = var.project_id

#   name    = "${local.vpc_name}-peering-gke-test-master"
#   network = module.vpc.network_self_link

#   purpose      = "VPC_PEERING"
#   address_type = "INTERNAL"

#   address       = "10.110.0.0"
#   prefix_length = 24 # min 24, but should be 28 "requires at least one allocated range to have minimal size; please make sure at least one allocated range will have prefix length at most '24'."
# }

# resource "google_service_networking_connection" "gke_test_private_master_connection" {
#   network = module.vpc.network_self_link
#   service = "servicenetworking.googleapis.com"

#   reserved_peering_ranges = [google_compute_global_address.gke_test_private_master_address.name]
# }
