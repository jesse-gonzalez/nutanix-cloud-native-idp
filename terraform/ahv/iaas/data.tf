
data "nutanix_cluster" "cluster" {
  name = var.ntnx_pe_cluster_name
}

data "nutanix_subnet" "net" {
  subnet_name = var.ntnx_pe_subnet_name
}

data "nutanix_category_key" "test_key_value" {
    name = nutanix_category_key.test_key_value.name
}

data "nutanix_image" "test" {
    image_id = nutanix_image.test.id
}

data "nutanix_image" "testname" {
    image_name = nutanix_image.test.name
}

#Get permission by name

data "nutanix_permission" "byname" {
    permission_name = "Access_Console_Virtual_Machine"
}


data "nutanix_role" "test" {
    role_id = nutanix_role.test.id
}