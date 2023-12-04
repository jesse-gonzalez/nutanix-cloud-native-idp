build {
  sources = [
    "source.nutanix.windows"
  ]

  provisioner "powershell" {
    only = ["nutanix.windows"]
    scripts = ["scripts/win-update.ps1"]
    pause_before = "2m"
  }

  provisioner "windows-restart" {
    only = ["nutanix.windows"]
    restart_timeout = "30m"
  }
  
}