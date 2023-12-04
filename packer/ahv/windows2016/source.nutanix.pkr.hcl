packer {
  required_plugins {
    nutanix = {
      version = ">= 0.1.0"
      source = "github.com/nutanix-cloud-native/nutanix"
    }
  }
}

source "nutanix" "windows" {
  nutanix_username = var.ntnx_pc_username
  nutanix_password = var.ntnx_pc_password
  nutanix_endpoint = var.ntnx_pc_ip
  nutanix_port     = var.ntnx_pc_port
  nutanix_insecure = var.ntnx_insecure
  cluster_name     = var.ntnx_pe_cluster_name
  cluster_name     = var.ntnx_pe_cluster_name
  
  vm_disks {
      image_type = "ISO_IMAGE"
      source_image_uuid = var.windows_2016_iso_uuid
  }

  vm_disks {
      image_type = "ISO_IMAGE"
      source_image_uuid = var.virtio_iso_uuid
  }

  vm_disks {
      image_type = "DISK"
      disk_size_gb = 60
  }

  vm_nics {
    subnet_name = var.ntnx_pe_subnet_name
  }
  
  cd_files         = ["scripts/gui/autounattend.xml","scripts/win-update.ps1"]
  
  image_name        ="win-{{isotime `Jan-_2-15:04:05`}}"
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  shutdown_timeout  = "3m"
  cpu               = 2
  os_type           = "Windows"
  memory_mb         = "8192"
  communicator      = "winrm"
  winrm_port        = 5986
  winrm_insecure    = true
  winrm_use_ssl     = true
  winrm_timeout     = "45m"
  winrm_password    = "packer"
  winrm_username    = "Administrator"
}