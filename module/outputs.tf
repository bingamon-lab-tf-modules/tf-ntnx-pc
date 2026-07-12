output "backup_targets" {
  description = "Backup target details"
  value = {
    for k, v in nutanix_pc_backup_target_v2.backup_target : k => {
      ext_id                = v.ext_id
      domain_manager_ext_id = v.domain_manager_ext_id
    }
  }
}

output "backup_target_ids" {
  description = "Map of backup target names to ext_ids"
  value = {
    for k, v in nutanix_pc_backup_target_v2.backup_target : k => v.ext_id
  }
}

output "restore_sources" {
  description = "Restore source details"
  value = {
    for k, v in nutanix_pc_restore_source_v2.restore_source : k => {
      ext_id = v.ext_id
    }
  }
}

output "restore_source_ids" {
  description = "Map of restore source names to ext_ids"
  value = {
    for k, v in nutanix_pc_restore_source_v2.restore_source : k => v.ext_id
  }
}

output "restores" {
  description = "Restore operation details"
  value = {
    for k, v in nutanix_pc_restore_v2.restore : k => {
      id                               = v.id
      restore_point_ext_id             = v.ext_id
      restore_source_ext_id            = v.restore_source_ext_id
      restorable_domain_manager_ext_id = v.restorable_domain_manager_ext_id
    }
  }
}

output "restore_ids" {
  description = "Map of restore operation names to IDs"
  value = {
    for k, v in nutanix_pc_restore_v2.restore : k => v.id
  }
}

output "pc_summary" {
  description = "Summary of Prism Central backup/restore resources"
  value = {
    total_backup_targets  = length(nutanix_pc_backup_target_v2.backup_target)
    total_restore_sources = length(nutanix_pc_restore_source_v2.restore_source)
    total_restores        = length(nutanix_pc_restore_v2.restore)
  }
}
