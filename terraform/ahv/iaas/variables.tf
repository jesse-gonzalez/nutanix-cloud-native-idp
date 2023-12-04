variable "ntnx_pc_username" {
  type = string
}

variable "ntnx_pc_password" {
  type = string
}

variable "ntnx_insecure" {
  type = string
  default = true
}

variable "ntnx_pc_ip" {
  type = string
}

variable "ntnx_pc_port" {
  type = string
}

variable "ntnx_pe_subnet_name" {
  type = string
}

variable "ntnx_pe_cluster_name" {
  type = string
}

variable "machine_image_name" {
  type = string
  default = "CentOS-7-x86_64-GenericCloud.qcow2"
}