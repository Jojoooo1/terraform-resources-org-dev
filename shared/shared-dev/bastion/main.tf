
locals {
  network                = data.terraform_remote_state.network.outputs.network_self_link
  network_private_subnet = data.terraform_remote_state.network.outputs.subnets_self_links[0]
  allow_ssh_from_iap_tag = data.terraform_remote_state.firewall.outputs.fw_allow_ssh_from_iap_tag
  allow_all_egress_tag   = data.terraform_remote_state.firewall.outputs.fw_allow_all_egress_tag

  service_dev_project_id = data.terraform_remote_state.dev_services.outputs.service_dev_project_id

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Bastion host 
  SSH: gcloud compute ssh --project="<your-project>" --zone="us-east1-b" bastion-host-dev --tunnel-through-iap
  SQL: gcloud compute ssh --project="<your-project>" --zone="us-east1-b" bastion-host-dev --tunnel-through-iap -- '/usr/local/bin/cloud_sql_proxy --private-ip --address 0.0.0.0 <your-connection-name>'
  psql: psql "host=10.100.0.6 dbname=api user=jonathan password=password"
 *****************************************/
module "bastion_with_iap" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "5.3"

  project = var.project_id
  network = local.network
  zone    = "us-east1-b"
  subnet  = local.network_private_subnet

  name                 = "bastion-host-dev"
  create_firewall_rule = false
  machine_type         = "e2-micro"
  disk_size_gb         = 10
  startup_script       = <<-EOF
    #!/bin/bash

    sudo apt-get update -y
    sudo apt install wget

    echo "****************************************************************"
    echo "installing cloud-ops-agent:"
    echo "****************************************************************"
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install

    echo "****************************************************************"
    echo "installing Cloud SQL proxy:"
    echo "****************************************************************"
    sudo wget https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.7.0/cloud-sql-proxy.linux.amd64 -O cloud_sql_proxy
    sudo chmod +x cloud_sql_proxy
    sudo mv cloud_sql_proxy /usr/local/bin

    echo "****************************************************************"
    echo "installing PSQL Client: (not recommended, only used for debugging)" 
    echo "****************************************************************"
    sudo apt-get install -y postgresql-client

    echo "****************************************************************"
    echo "installing tinyproxy:"
    echo "****************************************************************"
    sudo apt-get install -y tinyproxy

  EOF

  service_account_name               = "bastion-host-dev"
  service_account_roles_supplemental = ["roles/cloudsql.client"]
  members = [
    "user:jonathan.chevalier@cloud-diplomate.com"
  ]

  labels = local.common_labels
  tags   = setunion(local.allow_ssh_from_iap_tag, local.allow_all_egress_tag)
}

resource "google_project_iam_binding" "store_user" {
  project = local.service_dev_project_id
  role    = "roles/cloudsql.client"
  members = [
    "serviceAccount:${module.bastion_with_iap.service_account}"
  ]
}
