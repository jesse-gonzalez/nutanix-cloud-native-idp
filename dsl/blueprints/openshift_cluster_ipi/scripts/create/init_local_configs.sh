OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
NTNX_PC_IP=@@{pc_instance_ip}@@
NTNX_PC_PORT=@@{pc_instance_port}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@
NTNX_PE_IP=@@{prism_element_external_ip}@@
NTNX_PE_NET_NAME=@@{network}@@

BASE_FQDN=$OCP_CLUSTER_NAME.${OCP_BASE_DOMAIN}

OCP_API_VIP=@@{api_ipv4_vip}@@
OCP_APPS_INGRESS_VIP=@@{wildcard_ingress_ipv4_vip}@@

## create local environment secrets dir
mkdir -p .local/$OCP_CLUSTER_NAME/certs

## create local secrets files
echo '@@{ocp_pull_secret}@@' >| .local/$OCP_CLUSTER_NAME/pull-secret.json
echo '@@{Nutanix.secret}@@' >| .local/$OCP_CLUSTER_NAME/nutanix_key

## just in case this is run again against new cvm host after vip moves
ssh-keygen -R $NTNX_PE_IP

## configure ssh agent
eval "$(ssh-agent -s)"
chmod 0600 .local/$OCP_CLUSTER_NAME/nutanix_key
ssh-add .local/$OCP_CLUSTER_NAME/nutanix_key

## configure ip blacklist for ipam
sshpass -p '@@{Prism Central User.secret}@@' ssh nutanix@$NTNX_PE_IP -C "export PATH=$PATH:/usr/local/nutanix/bin ; acli net.add_to_ip_blacklist ${NTNX_PE_NET_NAME} ip_list=${OCP_API_VIP},${OCP_APPS_INGRESS_VIP}"

## validate with curl
##curl --silent --show-error --fail https://$BASE_FQDN:$NTNX_PC_PORT/