# change working directory
cd learn-terraform-provision-aks-cluster

# get output from terraform
AKS_RESOURCE_GROUP=$(terraform output -raw resource_group_name)
K8S_CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)

# initializa azure cli
AKS_SA_USERNAME=@@{Aks Service Account User.username}@@
AKS_SA_PASSWORD=@@{Aks Service Account User.secret}@@
AKS_SA_TENANT=@@{aks_sa_tenant}@@
AKS_SA_APPID=@@{aks_sa_appid}@@
AKS_SA_SUB=@@{aks_sa_subscriptionid}@@

# login and validate
az login --service-principal -u ${AKS_SA_USERNAME} -p ${AKS_SA_PASSWORD} --tenant ${AKS_SA_TENANT}
az aks list -o table

az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $K8S_CLUSTER_NAME --overwrite-existing --file $HOME/.kube/$K8S_CLUSTER_NAME.cfg

# echo "KUBECONFIG=$KUBECONFIG:$HOME/.kube/$K8S_CLUSTER_NAME.cfg" >> $HOME/.bashrc
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/$K8S_CLUSTER_NAME.cfg

# validate kubectl
kubectl get nodes -o wide
kubectl get pods -A
