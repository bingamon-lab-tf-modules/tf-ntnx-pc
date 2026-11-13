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

# Test 9: Object-store restore source, PC restore, SSL certificate, KMS, and
# populated data lookups validate v2.5.1 write-only/sensitive attributes and
# string-typed network.management_server.type.
run "v251_write_only_resources_and_populated_lookups" {
  command = plan

  variables {
    enable_data_lookups   = true
    domain_manager_ext_id = "00000000-0000-0000-0000-000000000001"

    restore_sources = {
      s3_source = {
        location_type = "object_store"
        object_store_config = {
          bucket_name       = "mock-restore-bucket"
          region            = "us-east-1"
          access_key_id     = "mock-restore-access-key"
          secret_access_key = "mock-restore-secret-key"
        }
        backup_policy = {
          rpo_in_minutes = 60
        }
      }
    }

    restores = {
      dr_restore = {
        ext_id                           = "22222222-2222-2222-2222-222222222222"
        restore_source_ext_id            = "33333333-3333-3333-3333-333333333333"
        restorable_domain_manager_ext_id = "00000000-0000-0000-0000-000000000001"
        domain_manager_config = {
          name = "pc-restored"
          size = "STARTER"
          credentials = [
            {
              username = "admin"
              password = "MockAdminPassword123!"
            }
          ]
        }
        domain_manager_network = {
          external_address_ipv4 = "192.0.2.10"
          name_servers          = ["192.0.2.53"]
          ntp_servers           = ["192.0.2.123"]
          external_networks = [
            {
              network_ext_id       = "44444444-4444-4444-4444-444444444444"
              default_gateway_ipv4 = "192.0.2.1"
              subnet_mask_ipv4     = "255.255.255.0"
              ip_ranges = [
                {
                  start_ipv4 = "192.0.2.20"
                  end_ipv4   = "192.0.2.25"
                }
              ]
            }
          ]
        }
      }
    }

    ssl_certificates = {
      pc_tls = {
        passphrase            = "mock-passphrase"
        private_key           = "mock-private-key-pem"
        public_certificate    = "mock-public-cert-pem"
        ca_chain              = "mock-ca-chain-pem"
        private_key_algorithm = "RSA_2048"
      }
    }

    key_management_servers = {
      kmip_vault = {
        name = "lab-kmip"
        kmip_key_vault = {
          ca_name     = "lab-kmip-ca"
          ca_pem      = "mock-ca-pem"
          cert_pem    = "mock-cert-pem"
          private_key = "mock-kmip-private-key"
          endpoints = [
            {
              ip   = "192.0.2.60"
              port = 5696
            }
          ]
        }
      }
      azure_vault = {
        name = "lab-akv"
        azure_key_vault = {
          endpoint_url           = "https://lab-akv.vault.azure.net"
          key_id                 = "lab-kek"
          tenant_id              = "55555555-5555-5555-5555-555555555555"
          client_id              = "66666666-6666-6666-6666-666666666666"
          client_secret          = "mock-azure-client-secret"
          credential_expiry_date = "2027-12-31"
        }
      }
    }
  }

  override_data {
    target = data.nutanix_clusters_v2.pc[0]
    values = {
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
          network = [
            {
              backplane                  = null
              external_address           = null
              external_data_services_ip  = null
              external_subnet            = null
              fqdn                       = "pc.example.test"
              http_proxy_list            = null
              http_proxy_white_list      = null
              internal_subnet            = null
              key_management_server_type = null
              management_server = [
                {
                  ip             = null
                  is_drs_enabled = false
                  is_in_use      = true
                  is_registered  = true
                  type           = "VCENTER"
                }
              ]
              masquerading_ip       = null
              masquerading_port     = null
              name_server_ip_list   = null
              nfs_subnet_white_list = null
              ntp_server_ip_list    = null
              smtp_server           = null
            }
          ]
          nodes          = []
          tenant_id      = ""
          upgrade_status = ""
          vm_count       = 0
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

  override_data {
    target = data.nutanix_pc_backup_targets_v2.existing[0]
    values = {
      backup_targets = [
        {
          backup_pause_reason = ""
          ext_id              = "77777777-7777-7777-7777-777777777777"
          is_backup_paused    = false
          last_sync_time      = "2026-11-13T00:00:00Z"
          links               = []
          location            = []
          tenant_id           = ""
        }
      ]
    }
  }

  assert {
    condition     = output.pc_summary.total_restore_sources == 1
    error_message = "Expected 1 object-store restore source"
  }

  assert {
    condition     = output.pc_summary.total_restores == 1 && contains(keys(output.restore_ids), "dr_restore")
    error_message = "Expected 1 restore operation keyed by dr_restore"
  }
}
