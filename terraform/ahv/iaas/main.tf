provider "nutanix" {
  username  = var.ntnx_pc_username
  password  = var.ntnx_pc_password
  endpoint  = var.ntnx_pc_ip
  insecure  = var.ntnx_insecure
  port      = var.ntnx_pc_port
}

resource "nutanix_category_key" "test_key_value"{
    name = "test_key"
    description = "Data Source CategoryKey Test with Values"
}

resource "nutanix_category_value" "test_value"{
    name = nutanix_category_key.test_key_value.name
    value = "test_key_value"
    description = "Data Source CategoryValue Test with Values"
}

resource "nutanix_image" "test" {
  name        = "Ubuntu"
  description = "Ubuntu"
  source_uri  = "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/mini.iso"
}

resource "nutanix_role" "test" {
    name        = "NAME"
    description = "DESCRIPTION"
    permission_reference_list {
        kind = "permission"
        uuid = "ID OF PERMISSION"
    }
}