variable "ntnx_pc_username" {
  type = string
}

variable "ntnx_pc_password" {
  type =  string
  sensitive = true
}

variable "ntnx_pc_ip" {
  type = string
}

variable "ntnx_pc_port" {
  type = number
}

variable "ntnx_insecure" {
  type = bool
  default = true
}

variable "ntnx_pe_subnet_name" {
  type = string
}

variable "ntnx_pe_cluster_name" {
  type = string
}

variable "windows_2016_iso_uuid" {
  type = string
}

variable "virtio_iso_uuid" {
  type = string
}
