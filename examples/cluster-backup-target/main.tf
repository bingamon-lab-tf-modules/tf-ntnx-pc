################################################################################
# PC Cluster Backup Target Example
################################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">= 2.4.2"
    }
  }
}

provider "nutanix" {
  username = var.nutanix_username
  password = var.nutanix_password
  endpoint = var.nutanix_endpoint
  port     = var.nutanix_port
  insecure = var.nutanix_insecure
}

# Get PC cluster information
data "nutanix_clusters_v2" "pc" {
  filter = "config/clusterFunction/any(t:t eq Clustermgmt.Config.ClusterFunctionRef'PRISM_CENTRAL')"
}

# Get PE clusters for backup target
data "nutanix_clusters_v2" "pe" {
  filter = "config/clusterFunction/any(t:t ne Clustermgmt.Config.ClusterFunctionRef'PRISM_CENTRAL')"
}

locals {
  domain_manager_ext_id = data.nutanix_clusters_v2.pc.cluster_entities[0].ext_id
  pe_cluster_ext_id     = data.nutanix_clusters_v2.pe.cluster_entities[0].ext_id
}

module "pc" {
  source = "../../module"

  enable_data_lookups   = true
  domain_manager_ext_id = local.domain_manager_ext_id

  # Cluster backup target configuration
  backup_targets = {
    cluster_backup = {
      domain_manager_ext_id = local.domain_manager_ext_id
      location_type         = "cluster"
      cluster_ext_id        = local.pe_cluster_ext_id
    }
  }
}

################################################################################
# Variables
################################################################################

variable "nutanix_username" {
  description = "Nutanix Prism Central username"
  type        = string
}

variable "nutanix_password" {
  description = "Nutanix Prism Central password"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  description = "Nutanix Prism Central endpoint"
  type        = string
}

variable "nutanix_port" {
  description = "Nutanix Prism Central port"
  type        = number
  default     = 9440
}

variable "nutanix_insecure" {
  description = "Allow insecure connection"
  type        = bool
  default     = true
}

################################################################################
# Outputs
################################################################################

output "backup_target_id" {
  description = "Backup target ID"
  value       = module.pc.backup_target_ids["cluster_backup"]
}

output "domain_manager_ext_id" {
  description = "Domain manager external ID"
  value       = local.domain_manager_ext_id
}
