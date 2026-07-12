check "backup_target_location_configuration" {
  assert {
    condition = alltrue([
      for k, v in var.backup_targets :
      v.location_type == "cluster" ? v.cluster_ext_id != null : v.object_store_config != null
    ])
    error_message = "Each backup target must specify cluster_ext_id (location_type = \"cluster\") or object_store_config (location_type = \"object_store\")."
  }
}

check "object_store_targets_have_credentials" {
  assert {
    condition = alltrue([
      for k, v in var.backup_targets :
      v.object_store_config != null if v.location_type == "object_store"
    ])
    error_message = "Object store backup targets must have object_store_config with credentials."
  }
}

check "object_store_targets_have_backup_policy" {
  assert {
    condition = alltrue([
      for k, v in var.backup_targets :
      v.backup_policy != null if v.location_type == "object_store"
    ])
    error_message = "Object store backup targets must have a backup policy with RPO."
  }
}

check "restore_source_location_configuration" {
  assert {
    condition = alltrue([
      for k, v in var.restore_sources :
      v.location_type == "cluster" ? v.cluster_ext_id != null : v.object_store_config != null
    ])
    error_message = "Each restore source must specify cluster_ext_id (location_type = \"cluster\") or object_store_config (location_type = \"object_store\")."
  }
}

check "restores_have_domain_manager" {
  assert {
    condition = alltrue([
      for k, v in var.restores :
      v.domain_manager_config != null
    ])
    error_message = "Restore operations must have domain manager configuration."
  }
}
