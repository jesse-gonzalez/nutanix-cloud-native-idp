APP_NAME=@@{calm_app}@@

# change working directory
cd learn-terraform-provision-eks-cluster

# get output from terraform
EKS_REGION=$(terraform output -raw region)
K8S_CLUSTER_NAME=$(terraform output -raw cluster_name)

SCALE_COUNT=@@{ScaleIn}@@

CURRENT_WORKER_COUNT=$(kubectl get nodes -o name | wc -l)

TARGET_WORKER_COUNT=$(expr $CURRENT_WORKER_COUNT - $SCALE_COUNT)

echo $TARGET_WORKER_COUNT

eksctl scale nodegroup --cluster=$K8S_CLUSTER_NAME --nodes=$TARGET_WORKER_COUNT, --name=ng-e56250ca
