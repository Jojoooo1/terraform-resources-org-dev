
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
  version = "~> 7.3"

  project_id   = var.project_id
  network_name = local.vpc_name

  shared_vpc_host                        = "true"
  delete_default_internet_gateway_routes = "true"
  routing_mode                           = "GLOBAL"

  subnets = [
    {
      subnet_name               = "cl-dpl-us-east1-dev-public"
      subnet_ip                 = "10.0.0.0/19"
      subnet_region             = "us-east1"
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    },
    {
      subnet_name               = "cl-dpl-us-east1-dev-private"
      subnet_ip                 = "10.0.32.0/19"
      subnet_region             = "us-east1"
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    }
  ]

  # Google Cloud security foundations guide v3: page 63
  # Some use cases, such as container-based workloads, can require additional aggregates. These need to be defined as subnet secondary ranges. For these cases, you can use address ranges that are taken from the reserved RFC 6598.
  secondary_ranges = {
    cl-dpl-us-east1-dev-public = [
      {
        range_name    = "cl-dpl-us-east1-dev-public"
        ip_cidr_range = "100.64.0.0/19"
      },
    ]
    cl-dpl-us-east1-dev-private = [
      {
        range_name    = "cl-dpl-us-east1-dev-private"
        ip_cidr_range = "100.64.32.0/19"
      },
    ]
  }


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

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    filter = "TRANSLATIONS_ONLY"
    enable = true
  }
}


/***************************************************************
  Configure Private Networking for GCP Services like Cloud SQL [...]
 **************************************************************/
resource "google_compute_global_address" "private_service_access_address" {
  project = var.project_id

  name    = "${local.vpc_name}-vpc-peering-internal"
  network = module.vpc.network_self_link

  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  address       = "10.100.0.0"
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network = module.vpc.network_self_link
  service = "servicenetworking.googleapis.com"

  reserved_peering_ranges = [google_compute_global_address.private_service_access_address.name]
}


