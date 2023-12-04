packer {
  required_plugins {
    nutanix = {
      version = ">= 0.1.0"
      source  = "github.com/nutanix-cloud-native/nutanix"
    }
  }
}

source "nutanix" "centos8" {
  nutanix_username = var.ntnx_pc_username
  nutanix_password = var.ntnx_pc_password
  nutanix_endpoint = var.ntnx_pc_ip
  nutanix_port     = var.ntnx_pc_port
  nutanix_insecure = var.ntnx_insecure
  cluster_name     = var.ntnx_pe_cluster_name
  os_type          = "Linux"
  
  vm_disks {
      image_type = "ISO_IMAGE"
      source_image_uuid = var.centos8_iso_uuid
  }

  vm_disks {
      image_type = "DISK"
      disk_size_gb = 40
  }

  vm_nics {
    subnet_name  = var.ntnx_pe_subnet_name
  }
  
  image_name        = "centos8-packer-image"
  #force_deregister  = true
  cd_files          = ["scripts/ks.cfg"]
  cd_label          = "OEMDRV"

  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  shutdown_timeout = "2m"
  ssh_password     = "packer"
  ssh_username     = "centos"
}
