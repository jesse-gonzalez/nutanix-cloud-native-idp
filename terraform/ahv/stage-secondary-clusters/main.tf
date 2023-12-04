resource "nutanix_subnet" "nutanix_ahv_ipam_subnet" {
  # What cluster will this VLAN live on?
  cluster_uuid = data.nutanix_cluster.cluster.id

  for_each = { for each in var.network_config : each.subnet_name => each }

  # General Information
  name        = each.value.subnet_name
  vlan_id     = each.value.vlan_id
  subnet_type = "VLAN"

  # Managed L3 Networks
  # This bit is only needed if you intend to turn on IPAM
  prefix_length = each.value.prefix_length

  default_gateway_ip = each.value.default_gateway_ip
  subnet_ip          = each.value.subnet_ip

  ip_config_pool_list_ranges = each.value.ip_config_pool_list_ranges

  dhcp_domain_name_server_list = each.value.dhcp_domain_name_server_list
  dhcp_domain_search_list      = each.value.dhcp_domain_search_list

  dhcp_options = {
    domain_name = each.value.dhcp_opt_domain_name
  }

}

  