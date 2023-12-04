variable "karbon_cni" {
  type        = string
  description = "karbon CNI name. Must be canal, calico, flannel, weave, or none. Default=calico"
  default     = "calico"
  validation {
    condition     = can(index(["flannel", "calico"], var.karbon_cni))
    error_message = "Variable karbon_cni must be flannel or calico."
  }
}

variable "karbon_cluster_name" {
  type        = string
  description = "karbon cluster name"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes Version"
  default     = "1.18.17-0"
}

variable "karbon_os_version" {
  type        = string
  description = "Karbon OS Version"
  default     = "ntnx-1.2"
}

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

variable "ntnx_pe_dataservice_ip" {
  type        = string
  description = "Prism Element dataservices IP address. Required for CSI installation"
}

variable "ntnx_pe_storage_container" {
  type        = string
  description = "This is the Nutanix Storage Container where the requested Persistent Volume Claims will get their volumes created. You can enable things like compression and deduplication in a Storage Container. The recommendation is to create at least one storage container in Prism Element well identified for Kubernetes usage. This will facilitate the search of persistent volumes when the environment scales."
}

variable "ntnx_pe_username" {
  type        = string
  description = "Prism Element username. Required for CSI installation"
}

variable "ntnx_pe_password" {
  type        = string
  description = "Prism Element password. Required for CSI installation"
}

variable "ntnx_pe_subnet_name" {
  type        = string
  description = "AHV Subnet used for karbon deployment."
}

variable "amount_of_karbon_worker_vms" {
  type        = number
  default     = 2
  description = "Amount of karbon worker VMs. Changing this value will result in scale-up or scale-down of the cluster"
  validation {
    condition     = var.amount_of_karbon_worker_vms > 0
    error_message = "Minimum 1 worker node is required."
  }
}

# variable "admin_vm_username" {
#   type        = string
#   description = "Username used for karbon installation. Default: nutanix"
#   default     = "nutanix"
# }

variable "karbon_worker_node_pool_config" {
  description = "Configuration of the karbon worker VMs."
  type = object({
    num_sockets          = number
    memory_size_mib      = number
    num_vcpus_per_socket = number
    disk_size_mib        = number
    }
  )
  default = {
    num_sockets          = 2
    memory_size_mib      = 8 * 1024
    disk_size_mib        = 131072
    num_vcpus_per_socket = 1
  }
}

variable "karbon_control_vm_config" {
  description = "Configuration of the karbon control VMs."
  type = object({
    num_sockets          = number
    memory_size_mib      = number
    num_vcpus_per_socket = number
    disk_size_mib        = number
    }
  )
  default = {
    num_sockets          = 2
    memory_size_mib      = 8 * 1024
    disk_size_mib        = 131072
    num_vcpus_per_socket = 1
  }
}

variable "karbon_admin_vm_config" {
  description = "Configuration of the karbon admin VM."
  type = object({
    num_sockets          = number
    memory_size_mib      = number
    num_vcpus_per_socket = number
    disk_size_mib        = number
    }
  )
  default = {
    num_sockets          = 2
    memory_size_mib      = 4 * 1024
    disk_size_mib        = 131072
    num_vcpus_per_socket = 1
  }
}
