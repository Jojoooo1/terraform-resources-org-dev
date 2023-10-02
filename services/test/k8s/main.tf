locals {
  network            = data.terraform_remote_state.network.outputs.network_self_link
  bastion_private_ip = data.terraform_remote_state.bastion.outputs.ip_address

  gke_name = "gke-test-1"

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}


/******************************************
  Kubernetes configuration https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/private-cluster
 *****************************************/
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "28.0.0"

  project_id = var.project_id
  name       = local.gke_name

  # region     = var.region # REGIONAL CLUSTER
  regional   = false      # ZONAL CLUSTER
  zones      = [var.zone] #
  network    = local.network
  subnetwork = var.subnetwork

  ip_range_pods     = var.ip_range_pods
  ip_range_services = var.ip_range_services

  enable_private_endpoint = true
  enable_private_nodes    = true

  master_ipv4_cidr_block = "10.110.0.0/28"
  master_authorized_networks = [
    {
      cidr_block   = "${local.bastion_private_ip}/32"
      display_name = "bastion-host-dev"
    }
  ]

  release_channel             = "REGULAR"
  datapath_provider           = "ADVANCED_DATAPATH" # enable dataplane V2 (cilium) https://isovalent.com/blog/post/cilium-hubble-cheat-sheet-observability/
  enable_shielded_nodes       = true
  enable_binary_authorization = true

  enable_vertical_pod_autoscaling      = true
  horizontal_pod_autoscaling           = true
  http_load_balancing                  = true
  network_policy                       = false # If dataplane V2 is enabled, the Calico add-on should be disabled.
  gce_pd_csi_driver                    = true
  filestore_csi_driver                 = true
  dns_cache                            = false
  monitoring_enable_managed_prometheus = false

  create_service_account = true
  grant_registry_access  = true
  registry_project_ids   = []

  remove_default_node_pool = true
  initial_node_count       = 1
  node_pools = [
    {
      name         = "node-pool-dev-01"
      machine_type = "e2-medium"
      # node_locations  = "us-east1-b,us-central1-c"
      # service_account = "project-service-account@<PROJECT ID>.iam.gserviceaccount.com"
      image_type = "COS_CONTAINERD"
      version    = "1.27.4-gke.900"

      initial_node_count = 1
      min_count          = 1
      max_count          = 1
      spot               = false
      # UPDATE TO FALSE FOR PRODUCTION
      preemptible = true

      auto_repair  = true
      auto_upgrade = false
      autoscaling  = true

      disk_type       = "pd-standard"
      local_ssd_count = 0
      disk_size_gb    = 100

      enable_gcfs                 = true
      enable_integrity_monitoring = true
      enable_secure_boot          = true
      logging_variant             = "DEFAULT"

      # tags = {}
    }
  ]
}
