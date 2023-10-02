variable "project_id" {
  description = "The project ID for the network"
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster"
  type        = string
}

variable "zone" {
  description = "The zone for the GKE cluster"
  type        = string
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork to host the cluster in (required)"
}

variable "ip_range_pods" {
  type        = string
  description = "The _name_ of the secondary subnet ip range to use for pods"
}

variable "ip_range_services" {
  type        = string
  description = "The _name_ of the secondary subnet range to use for services"
}
