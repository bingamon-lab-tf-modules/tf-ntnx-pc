data "nutanix_clusters_v2" "pc" {
  count  = var.enable_data_lookups ? 1 : 0
  filter = "config/clusterFunction/any(t:t eq Clustermgmt.Config.ClusterFunctionRef'PRISM_CENTRAL')"
}

data "nutanix_pc_backup_targets_v2" "existing" {
  count                 = var.enable_data_lookups && var.domain_manager_ext_id != null ? 1 : 0
  domain_manager_ext_id = var.domain_manager_ext_id
}
