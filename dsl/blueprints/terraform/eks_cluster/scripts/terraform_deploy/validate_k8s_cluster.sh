# change working directory
cd $(HOME)/terraform-stuff/eks-cluster

# get output from terraform
EKS_REGION=$(terraform output -raw region)
K8S_CLUSTER_NAME=$(terraform output -raw cluster_name)

aws eks --region $EKS_REGION update-kubeconfig --name $K8S_CLUSTER_NAME --alias $K8S_CLUSTER_NAME --kubeconfig $HOME/.kube/$K8S_CLUSTER_NAME.cfg

# echo "KUBECONFIG=$KUBECONFIG:$HOME/.kube/$K8S_CLUSTER_NAME.cfg" >> $HOME/.bashrc
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/$K8S_CLUSTER_NAME.cfg

# validate kubectl
kubectl get nodes -o wide
kubectl get pods -A
