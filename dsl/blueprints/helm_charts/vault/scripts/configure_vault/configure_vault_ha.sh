WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

sleep 20s

kubectl exec -n $NAMESPACE -ti pod/vault-0 -- sh -c "vault operator init -non-interactive > /tmp/.vault-init"

## unseal vault and validate status

UNSEAL1=$(kubectl exec -n $NAMESPACE -ti pod/vault-0 -- grep 'Unseal Key 1' /tmp/.vault-init | awk '{print $NF}')
UNSEAL2=$(kubectl exec -n $NAMESPACE -ti pod/vault-0 -- grep 'Unseal Key 2' /tmp/.vault-init | awk '{print $NF}')
UNSEAL3=$(kubectl exec -n $NAMESPACE -ti pod/vault-0 -- grep 'Unseal Key 3' /tmp/.vault-init | awk '{print $NF}')

for k in $UNSEAL1 $UNSEAL2 $UNSEAL3; do kubectl exec -n $NAMESPACE -ti pod/vault-0 -- vault operator unseal $k; done

kubectl exec -n $NAMESPACE -ti pod/vault-0 -- vault status

sleep 10s

## join remaining pods
for k in {0..4}; do kubectl exec -n $NAMESPACE -ti pod/vault-$k -- sh -c "vault operator raft join http://vault-0.vault-internal:8200 && sleep 5s"; done

for k in $UNSEAL1 $UNSEAL2 $UNSEAL3; do kubectl exec -n $NAMESPACE -ti pod/vault-1 -- vault operator unseal $k; done
for k in $UNSEAL1 $UNSEAL2 $UNSEAL3; do kubectl exec -n $NAMESPACE -ti pod/vault-2 -- vault operator unseal $k; done
for k in $UNSEAL1 $UNSEAL2 $UNSEAL3; do kubectl exec -n $NAMESPACE -ti pod/vault-3 -- vault operator unseal $k; done
for k in $UNSEAL1 $UNSEAL2 $UNSEAL3; do kubectl exec -n $NAMESPACE -ti pod/vault-4 -- vault operator unseal $k; done

## check vault status
for k in {0..4}; do kubectl exec -n $NAMESPACE -ti pod/vault-$k -- vault status; done

## check raft peer stats

sleep 10s

ACTIVE_VAULT_POD=$(kubectl get pod -n $NAMESPACE -o name -l vault-active=true)
kubectl exec -n $NAMESPACE -ti $ACTIVE_VAULT_POD -- vault operator raft list-peers

## validate login
INITIAL_ROOT_TOKEN=$(kubectl exec -n $NAMESPACE -ti pod/vault-0 -- grep 'Initial Root Token' /tmp/.vault-init | awk '{print $NF}')
kubectl exec -n $NAMESPACE -ti pod/vault-0 -- vault login $INITIAL_ROOT_TOKEN