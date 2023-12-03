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

# login and validate
az login --service-principal -u ${AKS_SA_USERNAME} -p ${AKS_SA_PASSWORD} --tenant ${AKS_SA_TENANT}
az aks list -o table

# terraform plan
terraform plan

# terraform apply
terraform apply -auto-approve

