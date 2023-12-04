/*
    DESCRIPTION:
    Microsoft Windows 10 variables used by the Packer Plugin for VMware vSphere (vsphere-iso).
*/

// Installation Operating System Metadata
vm_inst_os_language = "en-US"
vm_inst_os_keyboard = "en-US"
vm_inst_os_image    = "Windows 10 Pro"
vm_inst_os_kms_key  = "W269N-WFGWX-YVC9B-4J6C9-T83GX"

// Guest Operating System Metadata
vm_guest_os_language = "en-US"
vm_guest_os_keyboard = "en-US"
vm_guest_os_timezone = "UTC"
vm_guest_os_family   = "windows"
vm_guest_os_name     = "desktop"
vm_guest_os_version  = "10"
vm_guest_os_edition  = "pro"

// Virtual Machine Guest Operating System Setting
vm_guest_os_type = "windows9_64Guest"

// Virtual Machine Hardware Settings
vm_firmware              = "efi-secure"
vm_cdrom_type            = "sata"
vm_cpu_sockets           = 2
vm_cpu_cores             = 1
vm_cpu_hot_add           = false
vm_mem_size              = 4096
vm_mem_hot_add           = false
vm_disk_size             = 102400
vm_disk_controller_type  = ["lsilogic-sas"]
vm_disk_thin_provisioned = true
vm_network_card          = "vmxnet3"
vm_video_mem_size        = 131072
vm_video_displays        = 1

// Removable Media Settings
iso_urls           = [
    "http://artifactory-jcr.10.54.11.42.nip.io/artifactory/isos/microsoft/pe/WinPE_amd64.iso"
]

iso_path           = "iso/windows/pe"
iso_file           = "WinPE_amd64.iso"
iso_checksum_type  = "sha256"
iso_checksum_value = "845be826f5c770abc525fc5e00d54962f6adcd17c83416a6093671ea3387745e"

// iso_file           = "vsphere-win10-wim.iso"
// iso_checksum_type  = "sha256"
// iso_checksum_value = "6883ec3f2c4b12353b372a0eabaaaffd517f20b788bbf80685c941a621db43e3"

// Boot Settings
vm_boot_order       = "disk,cdrom"
vm_boot_wait        = "2s"
vm_boot_command     = [
  "<spacebar><wait30>",
  "diskpart /s F:\\CreatePartitions-UEFI.txt <enter><wait5>",
  "F:\\ApplyImage.bat E:\\vsphere-win10.wim <enter><wait5>",
  "wpeutil Reboot <enter>"
]

vm_shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""

// // Communicator Settings
communicator_port    = 5985
communicator_timeout = "12h"

// Provisioner Settings
scripts = ["scripts/windows/windows-prepare.ps1"]
inline = [
  "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))",
  "choco feature enable -n allowGlobalConfirmation",
  "Get-EventLog -LogName * | ForEach { Clear-EventLog -LogName $_.Log }"
]

// scripts = [""]
// inline = [""]

