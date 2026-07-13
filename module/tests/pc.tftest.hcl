###################################
# Unit Tests: Prism Central (backup / restore)
##################################################

#########################
# Provider
#########################

provider "nutanix" {
  username     = "dummy"
  password     = "dummy"
  endpoint     = "dummy.local"
  port         = 9440
  insecure     = true
  wait_timeout = 1
}

#########################
# Mock Data (Nutanix Provider)
#########################

mock_provider "nutanix" {

  # Prism Central cluster lookup (config.cluster_function = ["PRISM_CENTRAL"])
  mock_data "nutanix_clusters_v2" {
    defaults = {
      cluster_entities = [
        {
          ext_id                   = "00000000-0000-0000-0000-000000000001"
          name                     = "mock-prism-central-cluster"
          backup_eligibility_score = 0
          categories               = []
          cluster_profile_ext_id   = ""
          container_name           = ""
          expand                   = ""
          inefficient_vm_count     = 0
          links                    = []
          network                  = []
          nodes                    = []
          tenant_id                = ""
          upgrade_status           = ""
          vm_count                 = 0
          config = [
            {
              authorized_public_key_list       = []
              build_info                       = []
              cluster_arch                     = ""
              cluster_function                 = ["PRISM_CENTRAL"]
              cluster_software_map             = []
              encryption_in_transit_status     = ""
              encryption_option                = []
              encryption_scope                 = []
              fault_tolerance_state            = []
              hypervisor_types                 = ["AHV"]
              incarnation_id                   = 0
              is_available                     = true
              is_lts                           = false
              is_password_remote_login_enabled = false
              is_remote_support_enabled        = false
              operation_mode                   = ""
              pulse_status                     = []
              redundancy_factor                = 2
              timezone                         = ""
            }
          ]
        }
      ]
    }
  }

  # Existing backup targets lookup (empty response)
  mock_data "nutanix_pc_backup_targets_v2" {
    defaults = {
      backup_targets = []
    }
  }
}

#########################
# Tests
#########################

# Test 1: Empty configuration plans zero resources.
run "empty_config" {
  command = plan

  variables {
    backup_targets  = {}
    restore_sources = {}
    restores        = {}
  }

  assert {
    condition     = output.pc_summary.total_backup_targets == 0
    error_message = "Expected 0 backup targets for empty config"
  }

  assert {
    condition     = output.pc_summary.total_restore_sources == 0
    error_message = "Expected 0 restore sources for empty config"
  }

  assert {
    condition     = output.pc_summary.total_restores == 0
    error_message = "Expected 0 restores for empty config"
  }
}

# Test 2: Data lookups exercise the mocked PC cluster and backup-target
# data sources and plan zero managed resources.
run "data_lookups_enabled" {
  command = plan

  variables {
    enable_data_lookups   = true
    domain_manager_ext_id = "00000000-0000-0000-0000-000000000001"
    backup_targets        = {}
    restore_sources       = {}
    restores              = {}
  }

  assert {
    condition     = output.pc_summary.total_backup_targets == 0
    error_message = "Expected 0 backup targets when only data lookups are enabled"
  }
}

# Test 3: One PE-cluster backup target is planned and exposed via outputs.
run "single_cluster_backup_target" {
  command = plan

  variables {
    backup_targets = {
      cluster_backup = {
        domain_manager_ext_id = "00000000-0000-0000-0000-000000000001"
        location_type         = "cluster"
        cluster_ext_id        = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  assert {
    condition     = output.pc_summary.total_backup_targets == 1
    error_message = "Expected exactly 1 backup target"
  }

  assert {
    condition     = length(output.backup_target_ids) == 1
    error_message = "Expected backup_target_ids to contain 1 entry"
  }

  assert {
    condition     = contains(keys(output.backup_target_ids), "cluster_backup")
    error_message = "Expected backup_target_ids to contain the cluster_backup key"
  }
}

# Test 4: One S3 / object-store backup target with an RPO policy plans cleanly.
run "single_object_store_backup_target" {
  command = plan

  variables {
    backup_targets = {
      s3_backup = {
        domain_manager_ext_id = "00000000-0000-0000-0000-000000000001"
        location_type         = "object_store"
        object_store_config = {
          bucket_name       = "mock-backup-bucket"
          region            = "us-east-1"
          access_key_id     = "mock-access-key"
          secret_access_key = "mock-secret-key"
        }
        backup_policy = {
          rpo_in_minutes = 120
        }
      }
    }
  }

  assert {
    condition     = output.pc_summary.total_backup_targets == 1
    error_message = "Expected exactly 1 object-store backup target"
  }

  assert {
    condition     = contains(keys(output.backup_target_ids), "s3_backup")
    error_message = "Expected backup_target_ids to contain the s3_backup key"
  }
}

# Test 5: One cluster restore source is planned and exposed via outputs.
run "single_restore_source" {
  command = plan

  variables {
    restore_sources = {
      primary = {
        location_type  = "cluster"
        cluster_ext_id = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  assert {
    condition     = output.pc_summary.total_restore_sources == 1
    error_message = "Expected exactly 1 restore source"
  }

  assert {
    condition     = contains(keys(output.restore_source_ids), "primary")
    error_message = "Expected restore_source_ids to contain the primary key"
  }
}

# Test 6: A cluster backup target without a cluster_ext_id must fail the
# backup-target location-configuration validation.
run "backup_target_missing_cluster_ext_id" {
  command = plan

  variables {
    backup_targets = {
      bad = {
        domain_manager_ext_id = "00000000-0000-0000-0000-000000000001"
        location_type         = "cluster"
        cluster_ext_id        = null
      }
    }
  }

  expect_failures = [
    var.backup_targets,
  ]
}

# Test 7: A cluster restore source without a cluster_ext_id must fail the
# restore-source location-configuration validation.
run "restore_source_missing_cluster_ext_id" {
  command = plan

  variables {
    restore_sources = {
      bad = {
        location_type  = "cluster"
        cluster_ext_id = null
      }
    }
  }

  expect_failures = [
    var.restore_sources,
  ]
}

# Test 8: An object-store backup target without a backup policy must fail the
# object_store_targets_have_backup_policy check block.
run "object_store_target_missing_backup_policy" {
  command = plan

  variables {
    backup_targets = {
      s3_no_policy = {
        domain_manager_ext_id = "00000000-0000-0000-0000-000000000001"
        location_type         = "object_store"
        object_store_config = {
          bucket_name       = "mock-backup-bucket"
          region            = "us-east-1"
          access_key_id     = "mock-access-key"
          secret_access_key = "mock-secret-key"
        }
      }
    }
  }

  expect_failures = [
    check.object_store_targets_have_backup_policy,
  ]
}
