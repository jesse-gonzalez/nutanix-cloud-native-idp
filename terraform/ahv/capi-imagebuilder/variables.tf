
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

variable "ntnx_pe_ip" {
  type        = string
  description = "Prism Element IP address. Required for CSI installation"
}

variable "ntnx_pe_port" {
  type        = number
  default     = 9440
  description = "Prism Element port"
}

variable "ntnx_pe_subnet_name" {
  type        = string
  description = "AHV Subnet used for karbon deployment."
}

variable "image_url" {
  type = string
  default = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

variable "vm_name" {
  type = string
  default = "cluster-api-builder"
}

variable "vm_user" {
  type = string
  default = "nutanix"
}

variable "image_name" {
  type = string
  default = "ubuntu-builder"
}

variable "public_key_file_path" {
  type = string
  default = ".local/_common/nutanix_public_key"
}

variable "private_key_file_path" {
  type = string
  default = ".local/_common/nutanix_key"
}
