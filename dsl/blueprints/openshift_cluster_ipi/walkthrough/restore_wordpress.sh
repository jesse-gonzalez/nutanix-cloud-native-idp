## Things to Note

- OADP Bucket and Replication needs to be configured PRIOR to creating DataProtectionApplication/Backup/Schedule - otherwise, restic/velero metadata will be out of sync.
- At minimum, Secondary Cluster needed storage class to be configured with squash_type set to all_squash to get around restic pods (daemonset) using root account to set attributes on NFS files on local host_path (after pod_volume has been mounted) and failing with lhchown - operation not permitted.
  https://velero.io/docs/v1.6/restic/#how-backup-and-restore-work-with-restic - leveraging other UID/GID and root_squash option needs further testing/validating if needed
- During Restore to Secondary Cluster:
  - Re-Configure Ingress Routes if you wish to test/validate
  - ^^ above items could probably be done with restore hoooks

## Create Restore on Secondary Project 

```bash

BACKUP_NAME=wordpress-filesystem-backup

cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: restore-wordpress-filesystem-backup
  namespace: openshift-adp
spec:
  backupName: $BACKUP_NAME
  includedResources: []
  excludedResources:
  - nodes
  - events
  - events.events.k8s.io
  - backups.velero.io
  - restores.velero.io
  - resticrepositories.velero.io
  restorePVs: true
  hooks:
    resources:
      - name: wordpress-restore-hooks
        includedNamespaces:
        - wordpress
        includedResources:
        - pods
        labelSelector: 
          matchLabels:
            app.kubernetes.io/name: velero
            component: server
        postHooks:
        - init:
            initContainers:
            - name: restore-hook-init
              image: image-registry.openshift-image-registry.svc:5000/openshift/cli:latest
              command:
              - /bin/bash
              - -c
              - |
                kubectl get pods -n wordpress -o name | xargs kubectl delete
                oc delete route wordpress
                oc create route edge wordpress --service=wordpress
EOF

### using velero cli
## velero restore create --from-backup=wordpress-filesystem-backup -n openshift-adp --include-namespaces wordpress --restore-volumes=true
```

### Following procedures could be added as restore hooks

## Navigate delete all pods that are currently trying to run...rolling restart is not enough

kubectl get pods -n wordpress -o name | xargs kubectl delete

## Delete existing route and create new with secondary cluster site router.

#oc delete route wordpress && oc create route edge wordpress --service=wordpress --port http --insecure-policy Redirect --dry-run=client -o yaml  | kubectl apply -f -
oc create route edge wordpress --service=wordpress --port http --insecure-policy Redirect --dry-run=client -o yaml  | kubectl apply -f -

## Access Secondary Cluster and validate




## Monitor


## Addressing Partial restore issue

velero restore create --from-backup=wordpress-filesystem-backup -n openshift-adp \
  --include-namespaces wordpress \
  --exclude-resources replicationcontroller,deploymentconfig,templateinstances.template.openshift.io \
  --restore-volumes=true

oc get restore -n openshift-adp wordpress-filesystem-backup-20230327195217 -o jsonpath='{.status.phase}'

velero restore create --from-backup=wordpress-filesystem-backup -n openshift-adp \
  --include-namespaces wordpress \
  --include-resources replicationcontroller,deploymentconfig \
  --restore-volumes=true

velero restore describe wordpress-filesystem-backup-20230327193753 -n openshift-adp
velero restore logs wordpress-filesystem-backup-20230327193753 -n openshift-adp

## 

velero restore create --from-backup=wordpress-filesystem-backup-no-pvs -n openshift-adp \
  --include-namespaces wordpress \
  --restore-volumes=true
