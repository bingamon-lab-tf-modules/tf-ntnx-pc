# tf-ntnx-pc

## Table of Contents

## Overview

A description of the module goes here.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_nutanix"></a> [nutanix](#requirement\_nutanix) | >= 2.4.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nutanix"></a> [nutanix](#provider\_nutanix) | 2.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nutanix_pc_backup_target_v2.backup_target](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/pc_backup_target_v2) | resource |
| [nutanix_pc_restore_source_v2.restore_source](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/pc_restore_source_v2) | resource |
| [nutanix_pc_restore_v2.restore](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/pc_restore_v2) | resource |
| [nutanix_clusters_v2.pc](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/clusters_v2) | data source |
| [nutanix_pc_backup_targets_v2.existing](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/pc_backup_targets_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_targets"></a> [backup\_targets](#input\_backup\_targets) | Map of backup targets (cluster or object store) | <pre>map(object({<br/>    domain_manager_ext_id = string<br/>    location_type         = string # "cluster" or "object_store"<br/>    cluster_ext_id        = optional(string)<br/>    object_store_config = optional(object({<br/>      bucket_name       = string<br/>      region            = string<br/>      access_key_id     = string<br/>      secret_access_key = string<br/>    }))<br/>    backup_policy = optional(object({<br/>      rpo_in_minutes = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_domain_manager_ext_id"></a> [domain\_manager\_ext\_id](#input\_domain\_manager\_ext\_id) | Domain manager (Prism Central) external ID for data lookups | `string` | `null` | no |
| <a name="input_enable_data_lookups"></a> [enable\_data\_lookups](#input\_enable\_data\_lookups) | Enable data source lookups for existing resources | `bool` | `false` | no |
| <a name="input_restore_sources"></a> [restore\_sources](#input\_restore\_sources) | Map of restore sources (cluster or object store) | <pre>map(object({<br/>    location_type  = string # "cluster" or "object_store"<br/>    cluster_ext_id = optional(string)<br/>    object_store_config = optional(object({<br/>      bucket_name       = string<br/>      region            = string<br/>      access_key_id     = string<br/>      secret_access_key = string<br/>    }))<br/>    backup_policy = optional(object({<br/>      rpo_in_minutes = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_restores"></a> [restores](#input\_restores) | Map of restore operations | <pre>map(object({<br/>    ext_id                           = string<br/>    restore_source_ext_id            = string<br/>    restorable_domain_manager_ext_id = string<br/>    domain_manager_config = object({<br/>      name                        = string<br/>      size                        = string<br/>      should_enable_lockdown_mode = optional(bool)<br/>      build_version               = optional(string)<br/>      resource_config = optional(object({<br/>        container_ext_ids    = optional(list(string))<br/>        data_disk_size_bytes = optional(number)<br/>        memory_size_bytes    = optional(number)<br/>        num_vcpus            = optional(number)<br/>      }))<br/>    })<br/>    domain_manager_network = object({<br/>      external_address_ipv4 = string<br/>      name_servers          = list(string)<br/>      ntp_servers           = list(string)<br/>      external_networks = list(object({<br/>        network_ext_id       = string<br/>        default_gateway_ipv4 = string<br/>        subnet_mask_ipv4     = string<br/>        ip_ranges = list(object({<br/>          start_ipv4 = string<br/>          end_ipv4   = string<br/>        }))<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_target_ids"></a> [backup\_target\_ids](#output\_backup\_target\_ids) | Map of backup target names to ext\_ids |
| <a name="output_backup_targets"></a> [backup\_targets](#output\_backup\_targets) | Backup target details |
| <a name="output_outputs"></a> [outputs](#output\_outputs) | Aggregate of all module outputs (spec §7.6 contract, consumed by the landing zone as module.<x>.outputs). |
| <a name="output_pc_summary"></a> [pc\_summary](#output\_pc\_summary) | Summary of Prism Central backup/restore resources |
| <a name="output_restore_ids"></a> [restore\_ids](#output\_restore\_ids) | Map of restore operation names to IDs |
| <a name="output_restore_source_ids"></a> [restore\_source\_ids](#output\_restore\_source\_ids) | Map of restore source names to ext\_ids |
| <a name="output_restore_sources"></a> [restore\_sources](#output\_restore\_sources) | Restore source details |
| <a name="output_restores"></a> [restores](#output\_restores) | Restore operation details |
<!-- END_TF_DOCS -->
