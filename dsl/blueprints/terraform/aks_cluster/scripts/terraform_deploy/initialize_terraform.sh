# change working directory
cd learn-terraform-provision-aks-cluster

# remove versions file as it breaks with new version of terrform
if [ -e versions.tf ]; then
  rm -rf versions.tf
fi

echo '
appId    = "@@{aks_sa_appid}@@"
password = "@@{Aks Service Account User.secret}@@"
' > terraform.tfvars

# creating override file since kube_dashboard no longer supported for K8s 1.19+
cat << EOF >| ./override.tf
resource "azurerm_kubernetes_cluster" "default" {
  addon_profile {
    kube_dashboard {
      enabled = false
    }
  }
  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }
}
EOF

terraform init -upgrade
