

#### Connectivity Details

Wildcard Domain URL:
[https://@@{instance_name}@@.@@{Helm_HashiCorpVault.wildcard_ingress_dns_fqdn}@@](https://@@{instance_name}@@.@@{Helm_HashiCorpVault.wildcard_ingress_dns_fqdn}@@)

NipIO Domain URL:
[https://@@{instance_name}@@.@@{Helm_HashiCorpVault.nipio_ingress_domain}@@](https://@@{instance_name}@@.@@{Helm_HashiCorpVault.nipio_ingress_domain}@@)

#### Login to Vault via kubectl

VAULT_TOKEN=$(kubectl exec -ti vault-0 -n vault -- grep 'Initial Root Token' /tmp/.vault-init | awk '{print $NF}')
kubectl exec -ti vault-0 -n vault -- vault login $VAULT_TOKEN
kubectl exec -ti vault-0 -n vault -- vault status
