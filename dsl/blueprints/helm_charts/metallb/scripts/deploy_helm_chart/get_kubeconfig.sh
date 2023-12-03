echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-port @@{pc_instance_port}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo "Set KUBECONFIG"
karbonctl cluster kubeconfig --cluster-name ${K8S_CLUSTER_NAME} > ~/${K8S_CLUSTER_NAME}.cfg

chmod 600 ~/@@{k8s_cluster_name}@@.cfg

export KUBECONFIG=~/${K8S_CLUSTER_NAME}.cfg
