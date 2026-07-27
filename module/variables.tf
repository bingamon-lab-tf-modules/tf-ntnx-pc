variable "enable_data_lookups" {
  description = "Enable data source lookups for existing resources"
  type        = bool
  default     = false
}

variable "domain_manager_ext_id" {
  description = "Domain manager (Prism Central) external ID for data lookups"
  type        = string
  default     = null
}

variable "backup_targets" {
  description = "Map of backup targets (cluster or object store)"
  type = map(object({
    domain_manager_ext_id = string
    location_type         = string # "cluster" or "object_store"
    cluster_ext_id        = optional(string)
    object_store_config = optional(object({
      bucket_name       = string
      region            = string
      access_key_id     = string
      secret_access_key = string
    }))
    backup_policy = optional(object({
      rpo_in_minutes = number
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.backup_targets :
      v.location_type == "cluster" ? v.cluster_ext_id != null : v.object_store_config != null
    ])
    error_message = "Each backup target must set cluster_ext_id when location_type is \"cluster\", or object_store_config when location_type is \"object_store\"."
  }
}

variable "restore_sources" {
  description = "Map of restore sources (cluster or object store)"
  type = map(object({
    location_type  = string # "cluster" or "object_store"
    cluster_ext_id = optional(string)
    object_store_config = optional(object({
      bucket_name       = string
      region            = string
      access_key_id     = string
      secret_access_key = string
    }))
    backup_policy = optional(object({
      rpo_in_minutes = number
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.restore_sources :
      v.location_type == "cluster" ? v.cluster_ext_id != null : v.object_store_config != null
    ])
    error_message = "Each restore source must set cluster_ext_id when location_type is \"cluster\", or object_store_config when location_type is \"object_store\"."
  }
}

variable "restores" {
  description = "Map of restore operations"
  type = map(object({
    ext_id                           = string
    restore_source_ext_id            = string
    restorable_domain_manager_ext_id = string
    domain_manager_config = object({
      name                        = string
      size                        = string
      should_enable_lockdown_mode = optional(bool)
      build_version               = optional(string)
      resource_config = optional(object({
        container_ext_ids    = optional(list(string))
        data_disk_size_bytes = optional(number)
        memory_size_bytes    = optional(number)
        num_vcpus            = optional(number)
      }))
    })
    domain_manager_network = object({
      external_address_ipv4 = string
      name_servers          = list(string)
      ntp_servers           = list(string)
      external_networks = list(object({
        network_ext_id       = string
        default_gateway_ipv4 = string
        subnet_mask_ipv4     = string
        ip_ranges = list(object({
          start_ipv4 = string
          end_ipv4   = string
        }))
      }))
    })
  }))
  default = {}
}

variable "ssl_certificates" {
  description = "Map of SSL certificates to manage for cluster/PC instances (nutanix_ssl_certificate_v2)"
  type = map(object({
    cluster_ext_id        = optional(string)
    passphrase            = optional(string)
    private_key           = optional(string)
    public_certificate    = optional(string)
    ca_chain              = optional(string)
    private_key_algorithm = optional(string, "RSA_2048")
  }))
  default = {}
}

variable "key_management_servers" {
  description = "Map of Key Management Servers to configure (nutanix_key_management_server_v2)"
  type = map(object({
    name = string
    kmip_key_vault = optional(object({
      ca_name     = string
      ca_pem      = string
      cert_pem    = string
      private_key = string
      endpoints = list(object({
        ip   = string
        port = number
      }))
    }))
    azure_key_vault = optional(object({
      endpoint_url           = string
      key_id                 = string
      tenant_id              = string
      client_id              = string
      client_secret          = string
      credential_expiry_date = string
    }))
  }))
  default = {}
}
