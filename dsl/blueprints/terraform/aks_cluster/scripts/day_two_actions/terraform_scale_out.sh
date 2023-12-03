# change working directory
cd learn-terraform-provision-aks-cluster

# initializa azure cli
AKS_SA_USERNAME=@@{Aks Service Account User.username}@@
AKS_SA_PASSWORD=@@{Aks Service Account User.secret}@@
AKS_SA_TENANT=@@{aks_sa_tenant}@@
AKS_SA_APPID=@@{aks_sa_appid}@@
AKS_SA_SUB=@@{aks_sa_subscriptionid}@@

# need to export ARM variables for Terraform since SPN is being used.
export ARM_CLIENT_ID=${AKS_SA_APPID}
export ARM_CLIENT_SECRET=${AKS_SA_PASSWORD}
export ARM_SUBSCRIPTION_ID=${AKS_SA_SUB}
export ARM_TENANT_ID=${AKS_SA_TENANT}

# get terraform resources
AKS_RESOURCE_GROUP=$(terraform output -raw resource_group_name)
K8S_CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)

# login and validate
az login --service-principal -u ${AKS_SA_USERNAME} -p ${AKS_SA_PASSWORD} --tenant ${AKS_SA_TENANT}
az aks list -o table

az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $K8S_CLUSTER_NAME --overwrite-existing --file $HOME/.kube/$K8S_CLUSTER_NAME.cfg

echo "KUBECONFIG=$KUBECONFIG:$HOME/.kube/$K8S_CLUSTER_NAME.cfg" >> $HOME/.bashrc
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/$K8S_CLUSTER_NAME.cfg

# validate kubectl
kubectl get nodes -o wide

# change working directory
cd learn-terraform-provision-aks-cluster

SCALE_COUNT=@@{ScaleOut}@@

CURRENT_WORKER_COUNT=$(kubectl get nodes -o name | wc -l)

TARGET_WORKER_COUNT=$(expr $CURRENT_WORKER_COUNT + $SCALE_COUNT)

echo $TARGET_WORKER_COUNT

cat << EOF >| ./override.tf
resource "azurerm_kubernetes_cluster" "default" {
  addon_profile {
    kube_dashboard {
      enabled = false
    }
  }
  default_node_pool {
    name            = "default"
    node_count      = $TARGET_WORKER_COUNT
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }
}
EOF

terraform plan

terraform apply -auto-approve
