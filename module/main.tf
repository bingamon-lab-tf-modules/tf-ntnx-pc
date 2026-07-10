resource "nutanix_pc_backup_target_v2" "backup_target" {
  for_each = var.backup_targets

  domain_manager_ext_id = each.value.domain_manager_ext_id

  dynamic "location" {
    for_each = each.value.location_type == "cluster" ? [1] : []
    content {
      cluster_location {
        config {
          ext_id = each.value.cluster_ext_id
        }
      }
    }
  }

  dynamic "location" {
    for_each = each.value.location_type == "object_store" ? [1] : []
    content {
      object_store_location {
        provider_config {
          bucket_name = each.value.object_store_config.bucket_name
          region      = each.value.object_store_config.region
          credentials {
            access_key_id     = each.value.object_store_config.access_key_id
            secret_access_key = each.value.object_store_config.secret_access_key
          }
        }
        dynamic "backup_policy" {
          for_each = each.value.backup_policy != null ? [each.value.backup_policy] : []
          content {
            rpo_in_minutes = backup_policy.value.rpo_in_minutes
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      location[0].object_store_location[0].provider_config[0].credentials
    ]
  }
}

resource "nutanix_pc_restore_source_v2" "restore_source" {
  for_each = var.restore_sources

  dynamic "location" {
    for_each = each.value.location_type == "cluster" ? [1] : []
    content {
      cluster_location {
        config {
          ext_id = each.value.cluster_ext_id
        }
      }
    }
  }

  dynamic "location" {
    for_each = each.value.location_type == "object_store" ? [1] : []
    content {
      object_store_location {
        provider_config {
          bucket_name = each.value.object_store_config.bucket_name
          region      = each.value.object_store_config.region
          credentials {
            access_key_id     = each.value.object_store_config.access_key_id
            secret_access_key = each.value.object_store_config.secret_access_key
          }
        }
        dynamic "backup_policy" {
          for_each = each.value.backup_policy != null ? [each.value.backup_policy] : []
          content {
            rpo_in_minutes = backup_policy.value.rpo_in_minutes
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      location[0].object_store_location[0].provider_config[0].credentials
    ]
  }
}

resource "nutanix_pc_restore_v2" "restore" {
  for_each = var.restores

  restore_source_ext_id            = each.value.restore_source_ext_id
  restorable_domain_manager_ext_id = each.value.restorable_domain_manager_ext_id
  ext_id                           = each.value.ext_id

  domain_manager {
    config {
      name                        = each.value.domain_manager_config.name
      size                        = each.value.domain_manager_config.size
      should_enable_lockdown_mode = each.value.domain_manager_config.should_enable_lockdown_mode

      dynamic "build_info" {
        for_each = each.value.domain_manager_config.build_version != null ? [1] : []
        content {
          version = each.value.domain_manager_config.build_version
        }
      }

      dynamic "resource_config" {
        for_each = each.value.domain_manager_config.resource_config != null ? [each.value.domain_manager_config.resource_config] : []
        content {
          container_ext_ids    = resource_config.value.container_ext_ids
          data_disk_size_bytes = resource_config.value.data_disk_size_bytes
          memory_size_bytes    = resource_config.value.memory_size_bytes
          num_vcpus            = resource_config.value.num_vcpus
        }
      }
    }

    network {
      external_address {
        ipv4 {
          value = each.value.domain_manager_network.external_address_ipv4
        }
      }

      dynamic "name_servers" {
        for_each = each.value.domain_manager_network.name_servers
        content {
          ipv4 {
            value = name_servers.value
          }
        }
      }

      dynamic "ntp_servers" {
        for_each = each.value.domain_manager_network.ntp_servers
        content {
          ipv4 {
            value = ntp_servers.value
          }
        }
      }

      dynamic "external_networks" {
        for_each = each.value.domain_manager_network.external_networks
        content {
          network_ext_id = external_networks.value.network_ext_id
          default_gateway {
            ipv4 {
              value = external_networks.value.default_gateway_ipv4
            }
          }
          subnet_mask {
            ipv4 {
              value = external_networks.value.subnet_mask_ipv4
            }
          }
          dynamic "ip_ranges" {
            for_each = external_networks.value.ip_ranges
            content {
              begin {
                ipv4 {
                  value = ip_ranges.value.start_ipv4
                }
              }
              end {
                ipv4 {
                  value = ip_ranges.value.end_ipv4
                }
              }
            }
          }
        }
      }
    }
  }

  timeouts {
    create = "120m"
  }
}
