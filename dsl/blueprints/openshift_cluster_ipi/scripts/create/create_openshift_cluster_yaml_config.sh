#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

## set ocp cluster variables
OCP_API_VIP=@@{api_ipv4_vip}@@
OCP_APPS_INGRESS_VIP=@@{wildcard_ingress_ipv4_vip}@@
OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

## OCP_BASE_DOMAIN=ntnxlab.local
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@
OCP_WORKER_REPLICA_COUNT=@@{worker_machineset_count}@@
OCP_CONTROL_PLANE_REPLICA_COUNT=@@{control_plane_count}@@
OCP_PULL_SECRET=$(cat .local/$OCP_CLUSTER_NAME/pull-secret.json)

OCP_MACHINE_NETWORK=@@{machine_network}@@

NTNX_PC_FQDN=@@{ocp_ntnx_pc_dns_fqdn}@@
NTNX_PC_IP=@@{pc_instance_ip}@@
NTNX_PC_PORT=@@{pc_instance_port}@@
NTNX_PE_IP=@@{prism_element_external_ip}@@
NTNX_PE_PORT=9440
NTNX_PE_CLUSTER_UUID=@@{prism_element_uuid}@@
NTNX_PE_NETWORK_UUID=@@{network_uuid}@@

NTNX_PUBLIC_SSH_KEY="@@{nutanix_public_key}@@"

NTNX_PC_USER=@@{Prism Central User.username}@@
NTNX_PC_PASS=@@{Prism Central User.secret}@@

NTNX_PROJECT_NAME=@@{calm_project_name}@@

## manual task to generate install-config.yaml
## ./openshift-install create install-config --dir $OCP_BUILD_CACHE_INSTALL_DIR

cat <<EOF | tee $OCP_BUILD_CACHE_BASE/install-config.yaml
apiVersion: v1
baseDomain: $OCP_BASE_DOMAIN
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform:
    nutanix:
      cpus: 4
      coresPerSocket: 2
      memoryMiB: 16384
      osDisk:
        diskSizeGiB: 200
      categories: 
      - key: AppType
        value: KubernetesWorker
  replicas: $OCP_WORKER_REPLICA_COUNT
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform:
    nutanix:
      cpus: 4
      coresPerSocket: 2
      memoryMiB: 28672
      osDisk:
        diskSizeGiB: 200
      categories: 
      - key: AppType
        value: KubernetesControlPlane
  replicas: $OCP_CONTROL_PLANE_REPLICA_COUNT
credentialsMode: Manual
metadata:
  creationTimestamp: null
  name: $OCP_CLUSTER_NAME
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: $OCP_MACHINE_NETWORK
  serviceNetwork:
  - 172.30.0.0/16
platform:
  nutanix:
    apiVIP: $OCP_API_VIP
    ingressVIP: $OCP_APPS_INGRESS_VIP
    defaultMachinePlatform:
      bootType: Legacy
      categories: 
      - key: AppType
        value: Kubernetes
      project: 
        type: name
        name: $NTNX_PROJECT_NAME
    prismCentral:
      endpoint:
        address: $NTNX_PC_FQDN
        port: $NTNX_PC_PORT
      username: $NTNX_PC_USER
      password: $NTNX_PC_PASS
    prismElements:
    - endpoint:
        address: $NTNX_PE_IP
        port: $NTNX_PE_PORT
      uuid: $NTNX_PE_CLUSTER_UUID
    subnetUUIDs:
    - $NTNX_PE_NETWORK_UUID
publish: External
pullSecret: '$OCP_PULL_SECRET'
sshKey: |
  $NTNX_PUBLIC_SSH_KEY
EOF

## print output to STDOUT
##cat $OCP_BUILD_CACHE_BASE/install-config.yaml

## backup install config dir for future debugging
cp $OCP_BUILD_CACHE_BASE/install-config.yaml $OCP_BUILD_CACHE_BASE/install-config-bkup.yaml
