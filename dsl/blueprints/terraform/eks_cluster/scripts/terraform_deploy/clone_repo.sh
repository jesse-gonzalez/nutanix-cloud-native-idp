# cleanup existing repos
if [ -d cloud-native-calm ]; then
  rm -rf cloud-native-calm
fi

# Download Cloud-Native repo
git clone https://github.com/jesse-gonzalez/cloud-native-calm

# Copy Terraform Specific Repo Out
mkdir -p $(HOME)/terraform-stuff
cp cloud-native-calm/terraform/eks-cluster $(HOME)/terraform-stuff