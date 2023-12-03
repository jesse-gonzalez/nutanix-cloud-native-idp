#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

# OCP_CLUSTER_NAME=kalm-main-12-1-ocp
# OCP_BASE_DOMAIN=ncnlabs.ninja

INGRESS_NAME=wordpress.apps.${OCP_CLUSTER_NAME}.${OCP_BASE_DOMAIN}

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## create wordpress namespace/project
kubectl create ns wordpress --dry-run=client -o yaml | kubectl apply -f -

## update wordpress project
oc project wordpress
oc adm policy add-cluster-role-to-user cluster-admin -z wordpress-sa
oc adm policy add-cluster-role-to-user cluster-admin -z wordpress-mariadb

## deploy wordpress with files and volumes storage
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install wordpress bitnami/wordpress --namespace wordpress \
  --set wordpressUsername="admin" \
  --set wordpressPassword="nutanix/4u" \
  --set wordpressBlogName="Welcome to Openshift on Nutanix Demos" \
  --set replicaCount="2" \
  --set service.type="ClusterIP" \
  --set persistence.storageClass="nutanix-dynamicfile" \
  --set-string persistence."accessModes\[0\]"="ReadWriteMany" \
  --set mariadb.architecture="replication" \
  --set mariadb.auth.rootPassword="nutanix/4u" \
  --set mariadb.auth.password="nutanix/4u" \
  --set mariadb.primary.persistence.storageClass="nutanix-volume" \
  --set-string mariadb.primary.persistence."accessModes\[0\]"="ReadWriteOnce" \
  --set containerSecurityContext.allowPrivilegeEscalation=true \
  --set serviceAccount.create="true" \
  --set serviceAccount.name="wordpress-sa" \
  --wait \
  --wait-for-jobs

## create route for wordpress
oc create route edge wordpress --hostname $INGRESS_NAME --service=wordpress --port http --insecure-policy Redirect --dry-run=client -o yaml | kubectl apply -f -

## get route information and Access the Wordpress Application via Preferred Browser
kubectl get route wordpress -n wordpress

echo -e "\nWordpress Site: https://$(kubectl get route wordpress -n wordpress -o jsonpath='{.spec.host}')"
echo -e "\nWordpress Admin User: admin"
echo -e "\nWordpress Admin Password: nutanix/4u"
