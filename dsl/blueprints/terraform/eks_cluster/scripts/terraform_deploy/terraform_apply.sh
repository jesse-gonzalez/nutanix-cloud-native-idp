# change working directory
cd $(HOME)/terraform-stuff/eks-cluster

# initializa azure cli
AWS_ACCESS_KEY_ID=@@{Eks Service Account User.username}@@
AWS_SECRET_ACCESS_KEY=@@{Eks Service Account User.secret}@@

# update aws creds
mkdir -p ~/.aws

cat <<EOF >| ~/.aws/config
[default]
region = us-east-2
output = json
EOF


cat <<EOF >| ~/.aws/credentials
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF


# terraform plan
terraform plan

# terraform apply
terraform apply -auto-approve

