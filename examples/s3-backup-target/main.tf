################################################################################
# PC S3 Backup Target Example
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

locals {
  domain_manager_ext_id = data.nutanix_clusters_v2.pc.cluster_entities[0].ext_id
}

module "pc" {
  source = "../../module"

  enable_data_lookups   = true
  domain_manager_ext_id = local.domain_manager_ext_id

  # S3 backup target configuration
  backup_targets = {
    s3_backup = {
      domain_manager_ext_id = local.domain_manager_ext_id
      location_type         = "object_store"

      object_store_config = {
        bucket_name       = var.s3_bucket_name
        region            = var.s3_region
        access_key_id     = var.s3_access_key_id
        secret_access_key = var.s3_secret_access_key
      }

      backup_policy = {
        rpo_in_minutes = 120 # 2 hour RPO
      }
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

variable "s3_bucket_name" {
  description = "S3 bucket name for backup"
  type        = string
}

variable "s3_region" {
  description = "S3 bucket region"
  type        = string
  default     = "us-east-1"
}

variable "s3_access_key_id" {
  description = "S3 access key ID"
  type        = string
  sensitive   = true
}

variable "s3_secret_access_key" {
  description = "S3 secret access key"
  type        = string
  sensitive   = true
}

################################################################################
# Outputs
################################################################################

output "backup_target_id" {
  description = "Backup target ID"
  value       = module.pc.backup_target_ids["s3_backup"]
}
