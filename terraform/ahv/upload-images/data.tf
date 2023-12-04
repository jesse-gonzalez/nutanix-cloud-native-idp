
data "nutanix_cluster" "cluster" {
  name = var.ntnx_pe_cluster_name
}

data "nutanix_subnet" "net" {
  subnet_name = var.ntnx_pe_subnet_name
}