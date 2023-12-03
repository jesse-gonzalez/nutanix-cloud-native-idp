# change working directory
cd $(HOME)/terraform-stuff/eks-cluster

echo '
cluster_name = "@@{cluster_name}@@"
' > terraform.tfvars

terraform init -upgrade
