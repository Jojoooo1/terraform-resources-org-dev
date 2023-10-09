locals {
  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}


/******************************************
  Regional IP configuration
 *****************************************/

module "static_ips_regional" {
  source  = "terraform-google-modules/address/google"
  version = "3.1.3"

  # subnetwork       = "projects/gcp-network/regions/us-west1/subnetworks/dev-us-west1-dynamic"
  project_id   = var.project_id
  region       = var.region
  address_type = "EXTERNAL"

  enable_cloud_dns = true
  dns_project      = "cl-dpl-commons-dns-az9l"
  dns_domain       = "cloud-diplomate.com"
  dns_managed_zone = "cloud-diplomate-com"

  names = [
    "cl-dpl-service-test-rap0-k8s-test-nginx-ingress",
  ]

  dns_short_names = [
    "api-test"
  ]

}
