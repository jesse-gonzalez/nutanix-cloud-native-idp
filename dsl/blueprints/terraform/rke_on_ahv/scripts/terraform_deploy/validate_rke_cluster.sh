RKE_CLUSTER_NAME="@@{rke_cluster_name}@@"

# change working directory
cd rke-on-ahv/terraform

# migrate ssh keys
cp *$RKE_CLUSTER_NAME* $HOME/.ssh

# migrate kubectl config
cp kube_config_cluster.yml $HOME/.kube/$RKE_CLUSTER_NAME.cfg
cp kube_config_cluster.yml $HOME/.kube/config

echo "KUBECONFIG=$KUBECONFIG:$HOME/.kube/$RKE_CLUSTER_NAME.cfg" >> $HOME/.bashrc
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/$RKE_CLUSTER_NAME.cfg

# validate kubectl
kubectl get nodes -o wide
kubectl cluster-info
