## BETTER PROCESS? - https://rhthsa.github.io/openshift-demo/infrastructure-backup-etcd.html

# Make sure all is in good state before destroying things
## validate that all machines and nodes are ready and running
kubectl get nodes,machines -o wide -A

## validate that etcd cluster is fully functional
kubectl get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}'

## validate that cluster operators are running successfully
kubectl get clusteroperators

## create etcd backup by running job and validate that it ran successfully on each master node
kubectl get no -l node-role.kubernetes.io/master --no-headers -o name | xargs -I {} --  oc debug {} -- bash -c 'chroot /host sudo -E ls /home/core/backup'

## create generic namespace to validate that it's gone after restore
kubectl create ns post-etcd-backup-ns --dry-run=client -o yaml | kubectl apply -f -

## bring down etcd master-0 node via prism ui and validate node is unreachable
kubectl get nodes -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{"\t"}{range .spec.taints[*]}{.key}{" "}' | grep unreachable

## validate that cluster operators are starting to degrade
kubectl get clusteroperators

## validate that etcd clusters is unhealthy
kubectl get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}'

# Recovering the Failed Master Node

## After verifying everything above, you can begin the failed master node recovery procedure.
kubectl get pods -n openshift-etcd -l app=etcd

## Identify UNHEALTHY etcd member and get etcd member id so that you can remove from list.
UNHEALTHY_ETCD_MEMBER=$(kubectl get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}' | cut -d, -f2 | awk '{print $1}')
echo $UNHEALTHY_ETCD_MEMBER

HEALTHY_ETCD_MEMBER=$(kubectl get pods -n openshift-etcd -l app=etcd --no-headers -o name | grep -v $UNHEALTHY_ETCD_MEMBER | head -n 1)
echo $HEALTHY_ETCD_MEMBER

UNHEALTHY_ETCD_MEMBER_ID=$(oc rsh -n openshift-etcd $HEALTHY_ETCD_MEMBER etcdctl member list | grep -i $UNHEALTHY_ETCD_MEMBER | cut -d ',' -f1)
echo $UNHEALTHY_ETCD_MEMBER_ID

## Remove unhealthy etcd member from list
oc rsh -n openshift-etcd $HEALTHY_ETCD_MEMBER etcdctl member remove $UNHEALTHY_ETCD_MEMBER_ID

## Validate that unhealthy etcd member has been removed
oc rsh -n openshift-etcd $HEALTHY_ETCD_MEMBER etcdctl member list -w table

## Loop through secrets with name of unhealthy etcd member and delete
kubectl get secrets -n openshift-etcd -o name | grep $UNHEALTHY_ETCD_MEMBER | xargs -I {} kubectl delete -n openshift-etcd {}

## Obtain the machine configuration for the unhealthy member
## kubectl get machines -n openshift-machine-api $UNHEALTHY_ETCD_MEMBER -o yaml

oc debug $UNHEALTHY_ETCD_MEMBER -- bash -c 'chroot /host sudo -E mkdir /var/lib/etcd-backup && mv /etc/kubernetes/manifests/etcd-pod.yaml /var/lib/etcd-backup/ && mv /var/lib/etcd/ /tmp'
oc rsh -n openshift-etcd $HEALTHY_ETCD_MEMBER etcdctl endpoint health