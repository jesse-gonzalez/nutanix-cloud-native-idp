
variable "ntnx_pc_username" {
  type        = string
  description = "Prism Central username"
}

variable "ntnx_pc_password" {
  type        = string
  description = "Prism Central password"
}

variable "ntnx_pc_ip" {
  type        = string
  description = "Prism Central IP address"
}

variable "ntnx_pe_cluster_name" {
  type        = string
  description = "Prism Element Cluster Name"
}

variable "network_config" {
  type = list(object({
    subnet_name = string
    vlan_id = string
    prefix_length = number
    default_gateway_ip = string
    subnet_ip = string
    ip_config_pool_list_ranges = list(string)
    dhcp_opt_domain_name = string
    dhcp_domain_name_server_list = list(string)
    dhcp_domain_search_list = list(string)
  }))
  description = "network config"
}