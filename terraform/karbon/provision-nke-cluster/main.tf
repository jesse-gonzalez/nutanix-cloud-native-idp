resource "nutanix_karbon_cluster" "karbon_cluster" {
  name       = var.karbon_cluster_name
  version    = var.k8s_version
  storage_class_config {
    reclaim_policy = "Delete"
    volumes_config {
      file_system                = "ext4"
      flash_mode                 = false
      password                   = var.ntnx_pe_password
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
      storage_container          = var.ntnx_pe_storage_container
      username                   = var.ntnx_pe_username
    }
  }
  cni_config {
    calico_config {
      ip_pool_config {
        cidr = "172.20.0.0/16"
      }
    }
  }
  worker_node_pool {
    node_os_version = var.karbon_os_version
    num_instances   = 1
    ahv_config {
      network_uuid               = data.nutanix_subnet.subnet.id
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
    }
  }
  etcd_node_pool {
    node_os_version = var.karbon_os_version
    num_instances   = 1
    ahv_config {
      network_uuid               = data.nutanix_subnet.subnet.id
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
    }
  }
  master_node_pool {
    node_os_version = var.karbon_os_version
    num_instances   = 1
    ahv_config {
      network_uuid               = data.nutanix_subnet.subnet.id
      prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
    }
  }
}
