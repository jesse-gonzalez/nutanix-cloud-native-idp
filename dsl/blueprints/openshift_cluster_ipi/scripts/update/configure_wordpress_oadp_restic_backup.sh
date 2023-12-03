#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## BACKUP & RESTORE WORKFLOW USING RESTIC
## velero tool is needed:
## alias velero='kubectl -n openshift-adp exec deployment/velero -c velero -it -- ./velero -n openshift-adp'
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
  labels:
    velero.io/storage-location: default
  namespace: openshift-adp
spec:
  defaultVolumesToRestic: true
  snapshotVolumes: true
  hooks: {}
  includedNamespaces:
    - wordpress
  includedResources: []
  excludedNamespaces: []
  storageLocation: oadp-dpa-ntnx-1
  ttl: 72h0m0s
EOF

# DO NOT INCLUDE includeClusterResources: false - known issue

## validate that backups, restic repositories, podvolumebackups have been created
kubectl -n openshift-adp describe backup wordpress-filesystem-backup -n openshift-adp
#kubectl -n openshift-adp get resticrepositories -l velero.io/volume-namespace=wordpress
#kubectl -n openshift-adp get podvolumebackups -l velero.io/backup-name=wordpress-filesystem-backup

## if you have velero cli installed
#velero -n openshift-adp get backup wordpress-filesystem-backup
#velero -n openshift-adp backup logs wordpress-filesystem-backup --insecure-skip-tls-verify

## Configure Scheduled Backup Job
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
