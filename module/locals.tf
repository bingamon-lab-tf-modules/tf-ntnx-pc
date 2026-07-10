locals {
  cluster_backup_targets       = { for k, v in var.backup_targets : k => v if v.location_type == "cluster" }
  object_store_backup_targets  = { for k, v in var.backup_targets : k => v if v.location_type == "object_store" }
  cluster_restore_sources      = { for k, v in var.restore_sources : k => v if v.location_type == "cluster" }
  object_store_restore_sources = { for k, v in var.restore_sources : k => v if v.location_type == "object_store" }
}
