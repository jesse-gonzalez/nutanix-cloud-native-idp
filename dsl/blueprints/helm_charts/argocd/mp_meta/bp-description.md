

#### Connectivity Details

NIPIO Ingress URL:

[https://@@{instance_name}@@.@@{Helm_ArgoCd.nipio_ingress_domain}@@](https://@@{instance_name}@@.@@{Helm_ArgoCd.nipio_ingress_domain}@@)

Wildcard Domain Ingress URL:

[https://@@{instance_name}@@.@@{Helm_ArgoCd.wildcard_ingress_dns_fqdn}@@](https://@@{instance_name}@@.@@{Helm_ArgoCd.wildcard_ingress_dns_fqdn}@@)

#### First Login Details

Username: `admin`

Temporary_Password can be found using the following:

`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo`
