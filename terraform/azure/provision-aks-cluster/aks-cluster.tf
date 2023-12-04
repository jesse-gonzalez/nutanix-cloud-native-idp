provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${var.kubernetes_cluster_name}-rg"
  location = "East US 2"

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = var.kubernetes_cluster_name
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = var.kubernetes_cluster_name

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}
