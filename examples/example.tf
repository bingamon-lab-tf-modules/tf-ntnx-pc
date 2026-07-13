terraform {
  required_version = ">= 1.9.0"
}

################################################################################
# Prism Central backup targets
#
# Demonstrates one PE-cluster backup target and one S3 / object-store backup
# target (with an RPO policy) using the lab flat variable schema
# (location_type / cluster_ext_id / object_store_config).
################################################################################

module "pc" {
  source = "git::https://github.com/bingamon-lab-tf-modules/tf-ntnx-pc.git//module?ref=v0.1.0"

  backup_targets = {
    # PE-cluster backup target
    pe_cluster = {
      domain_manager_ext_id = var.domain_manager_ext_id
      location_type         = "cluster"
      cluster_ext_id        = var.pe_cluster_ext_id
    }

    # S3 / object-store backup target with a 2 hour RPO
    object_store = {
      domain_manager_ext_id = var.domain_manager_ext_id
      location_type         = "object_store"

      object_store_config = {
        bucket_name       = var.s3_bucket_name
        region            = var.s3_region
        access_key_id     = var.s3_access_key_id
        secret_access_key = var.s3_secret_access_key
      }

      backup_policy = {
        rpo_in_minutes = 120
      }
    }
  }
}

################################################################################
# Variables
################################################################################

variable "domain_manager_ext_id" {
  description = "Prism Central (domain manager) external ID that owns the backup targets"
  type        = string
}

variable "pe_cluster_ext_id" {
  description = "Prism Element cluster external ID used as the cluster backup target"
  type        = string
}

variable "s3_bucket_name" {
  description = "Object-store bucket name for the S3 backup target"
  type        = string
}

variable "s3_region" {
  description = "Object-store bucket region"
  type        = string
  default     = "us-east-1"
}

variable "s3_access_key_id" {
  description = "Object-store access key ID"
  type        = string
  sensitive   = true
}

variable "s3_secret_access_key" {
  description = "Object-store secret access key"
  type        = string
  sensitive   = true
}

################################################################################
# Outputs
################################################################################

output "backup_target_ids" {
  description = "Map of backup target names to ext_ids"
  value       = module.pc.backup_target_ids
}
