locals {
  cluster_backup_targets       = { for k, v in var.backup_targets : k => v if v.location_type == "cluster" }
  object_store_backup_targets  = { for k, v in var.backup_targets : k => v if v.location_type == "object_store" }
  cluster_restore_sources      = { for k, v in var.restore_sources : k => v if v.location_type == "cluster" }
  object_store_restore_sources = { for k, v in var.restore_sources : k => v if v.location_type == "object_store" }

  # PC clusters from data lookup
  pc_clusters = var.enable_data_lookups ? try(data.nutanix_clusters_v2.pc[0].cluster_entities, []) : []

  # Domain manager ext ID: explicit variable wins, otherwise derived from the PC lookup
  domain_manager_ext_id = var.domain_manager_ext_id != null ? var.domain_manager_ext_id : (
    length(local.pc_clusters) > 0 ? local.pc_clusters[0].ext_id : null
  )

  # Existing backup targets from data lookup
  existing_backup_targets = var.enable_data_lookups && var.domain_manager_ext_id != null ? try(data.nutanix_pc_backup_targets_v2.existing[0].backup_targets, []) : []

  # Existing backup target details keyed by ext_id
  backup_target_id_by_name = {
    for target in local.existing_backup_targets : target.ext_id => target
  }
}
