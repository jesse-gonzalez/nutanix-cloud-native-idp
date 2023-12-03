# cleanup existing repos
if [ -d learn-terraform-provision-aks-cluster ]; then
  rm -rf learn-terraform-provision-aks-cluster
fi

# Download Terraform AKS repo
git clone https://github.com/hashicorp/learn-terraform-provision-aks-cluster
