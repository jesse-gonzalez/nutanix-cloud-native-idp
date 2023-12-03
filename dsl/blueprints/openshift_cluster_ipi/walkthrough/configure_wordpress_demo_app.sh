#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

# OCP_CLUSTER_NAME=kalm-main-15-1-ocp
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
  --set wordpressBlogName="Welcome to Nutanix on Openshift Demos" \
  --set replicaCount="2" \
  --set service.type="ClusterIP" \
  --set persistence.storageClass="nutanix-dynamicfile-all-squash" \
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

## validate pre-requisites

## BACKUP & RESTORE WORKFLOW USING RESTIC
## velero tool is needed:
## alias velero='kubectl -n openshift-adp exec deployment/velero -c velero -it -- ./velero'
## key velero api resources
## backupstoragelocations,backups,schedules,podvolumebackups,resticrepositories,volumesnapshotlocations,restores,podvolumerestores
## key adp api resources
## volumesnapshotbackups,volumesnapshotrestores,cloudstorages,dataprotectionapplications

## For backups that are created by using Restic, exclude both the PVC and any pods that mount the PVC.
#kubectl get pod -o name -n wordpress | xargs -I {} kubectl label {} velero.io/exclude-from-backup=true --overwrite
#kubectl get pvc -o name -n wordpress | xargs -I {} kubectl label {} velero.io/exclude-from-backup=true --overwrite
#kubectl get pvc -o name -n wordpress | xargs -I {} kubectl label {} velero.io/exclude-from-backup-

## Example Config to create an on-demand Backup of Wordpress app
cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: wordpress-filesystem-backup
  namespace: openshift-adp
spec:
  defaultVolumesToRestic: true
  snapshotVolumes: true
  hooks: {}
  includedNamespaces:
    - wordpress
  includedResources: []
  excludedResources: []
  excludedNamespaces: []
  storageLocation: oadp-dpa-ntnx-1
  ttl: 72h0m0s
EOF

## validate that backups, restic repositories, podvolumebackups have been created
kubectl -n openshift-adp describe backup wordpress-filesystem-backup -n openshift-adp
kubectl -n openshift-adp get resticrepositories -l velero.io/volume-namespace=wordpress
kubectl -n openshift-adp get podvolumebackups -l velero.io/backup-name=wordpress-filesystem-backup

## if you have velero cli installed
velero -n openshift-adp get backup wordpress-filesystem-backup
velero -n openshift-adp backup logs wordpress-filesystem-backup --insecure-skip-tls-verify

##########
## Recover to same namespace
kubectl delete ns wordpress

## restore from on-demand wordpress
cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: wordpress-filesystem-restore
  namespace: openshift-adp
spec:
  backupName: wordpress-filesystem-backup
  includedNamespaces:
    - wordpress
  includedResources: [] 
  excludedResources:
  - nodes
  - events
  - events.events.k8s.io
  - backups.velero.io
  - restores.velero.io
  - resticrepositories.velero.io
  restorePVs: false
EOF

## validate that restore, restic repositories, podvolumerestores have been created
kubectl -n openshift-adp describe restores.velero.io wordpress-filesystem-restore -n openshift-adp
kubectl -n openshift-adp get resticrepositories -l velero.io/volume-namespace=wordpress -o yaml
kubectl -n openshift-adp get podvolumerestores -l velero.io/restore-name=wordpress-filesystem-restore -o yaml

## if you have velero cli installed
velero -n openshift-adp get restore wordpress-filesystem-restore
velero -n openshift-adp restore logs wordpress-filesystem-restore --insecure-skip-tls-verify

#########
## Restoring into a different namespace
velero restore create <RESTORE_NAME> \
  --from-backup <BACKUP_NAME> \
  --namespace-mappings old-ns-1:new-ns-1,old-ns-2:new-ns-2

## restore from on-demand wordpress
cat <<EOF | kubectl apply --dry-run=client -o yaml -f  -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: wordpress-filesystem-restore-ns2
  namespace: openshift-adp
spec:
  backupName: wordpress-filesystem-backup
  includedNamespaces:
    - wordpress
  includedResources: [] 
  excludedResources:
  - nodes
  - events
  - events.events.k8s.io
  - backups.velero.io
  - restores.velero.io
  - resticrepositories.velero.io
  restorePVs: false
  namespaceMapping:
    - wordpress:wordpress-ns2
EOF

### https://velero.io/docs/v1.9/restore-reference/

#########
## General Troubleshooting
## looking at velero and restic logs
kubectl -n openshift-adp logs deploy/velero
kubectl -n openshift-adp logs ds/restic

## Create Schedule Job
cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: schedule-wordpress-15-min-filesystem-backup
  namespace: openshift-adp
spec:
  schedule: "*/15 * * * *"
  template:
    defaultVolumesToRestic: true
    snapshotVolumes: true
    hooks: {}
    includedNamespaces:
      - wordpress
    includedResources: []
    excludedResources:
    - events
    - events.events.k8s.io
    excludedNamespaces: []
    storageLocation: oadp-dpa-ntnx-1
    ttl: 72h0m0s
EOF

## restore from scheduled snapshot

cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: wordpress-filesystem-restore-20221206211526-2
  namespace: openshift-adp
spec:
  backupName: schedule-wordpress-15-min-filesystem-backup-20221206211526
  includedResources: [] 
  excludedResources:
  - nodes
  - events
  - events.events.k8s.io
  - backups.velero.io
  - restores.velero.io
  - resticrepositories.velero.io
  restorePVs: true
EOF
