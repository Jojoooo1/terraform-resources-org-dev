<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.83 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.83 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion_with_iap"></a> [bastion\_with\_iap](#module\_bastion\_with\_iap) | terraform-google-modules/bastion-host/google | 5.3 |

## Resources

| Name | Type |
|------|------|
| [terraform_remote_state.firewall](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.network](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID for the network | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region for subnetworks in the network | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->