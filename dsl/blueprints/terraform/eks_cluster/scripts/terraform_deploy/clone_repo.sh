# cleanup existing repos
if [ -d nutanix-cloud-native-idp ]; then
  rm -rf nutanix-cloud-native-idp
fi

# Download Cloud-Native repo
git clone https://github.com/jesse-gonzalez/nutanix-cloud-native-idp

# Copy Terraform Specific Repo Out
mkdir -p $(HOME)/terraform-stuff
cp nutanix-cloud-native-idp/terraform/eks-cluster $(HOME)/terraform-stuff