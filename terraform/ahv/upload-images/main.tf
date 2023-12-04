provider "nutanix" {
  username  = var.ntnx_pc_username
  password  = var.ntnx_pc_password
  endpoint  = var.ntnx_pc_ip
  insecure  = var.ntnx_insecure
  port      = var.ntnx_pc_port
}

resource "nutanix_image" "centos7" {
  name        = var.centos7_iso_name
  source_uri  = var.centos7_iso_uri
}

resource "nutanix_image" "centos8" {
  name        = var.centos8_iso_name
  source_uri  = var.centos8_iso_uri
}

resource "nutanix_image" "rhel7" {
  name        = var.rhel7_iso_name
  source_uri  = var.rhel7_iso_uri
}

resource "nutanix_image" "rhel8" {
  name        = var.rhel8_iso_name
  source_uri  = var.rhel8_iso_uri
}

resource "nutanix_image" "windows2016" {
  name        = var.windows_2016_iso_name
  source_uri  = var.windows_2016_iso_uri
}

resource "nutanix_image" "virtio" {
  name        = var.virtio_iso_name
  source_uri  = var.virtio_iso_uri
}

resource "nutanix_image" "ubuntu1804" {
  name        = var.ubuntu1804_iso_name
  source_uri  = var.ubuntu1804_iso_uri
}

# resource "nutanix_image" "windowsPE" {
#   name        = var.windows_pe_iso_name
#   source_uri  = var.windows_pe_iso_uri
# }

# resource "nutanix_image" "windows10" {
#   name        = var.windows_10_iso_name
#   source_uri  = var.windows_10_iso_uri
# }

output "cluster_uuid" {
  value = data.nutanix_cluster.cluster.cluster_id
}

output "subnet_uuid" {
  value = data.nutanix_subnet.net.id
}

output "centos7_uuid" {
  value = resource.nutanix_image.centos7.id
}

output "centos8_uuid" {
  value = resource.nutanix_image.centos8.id
}

output "rhel7_uuid" {
  value = resource.nutanix_image.rhel7.id
}

output "rhel8_uuid" {
  value = resource.nutanix_image.rhel8.id
}

output "win2016_uuid" {
  value = resource.nutanix_image.windows2016.id
}

output "virtio_uuid" {
  value = resource.nutanix_image.virtio.id
}

output "ubuntu1804_uuid" {
  value = resource.nutanix_image.ubuntu1804.id
}
