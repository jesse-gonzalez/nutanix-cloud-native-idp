

#### Connectivity Details

TOKEN:

Run following command via KUBECTL to get initial bearer token:

```bash
kubectl get secret $(kubectl get serviceaccount -l app=k10 -o jsonpath="{.items[].secrets[].name}" --namespace kasten-io) --namespace kasten-io -ojsonpath="{.data.token}{'\n'}" | base64 -d && echo
```

URL:

[https://@@{instance_name}@@.@@{Helm_Kasten.nipio_ingress_domain}@@/k10](https://@@{instance_name}@@.@@{Helm_Kasten.nipio_ingress_domain}@@/k10)

Multi-Cluster URL:

[https://@@{instance_name}@@.@@{Helm_Kasten.nipio_ingress_domain}@@/k10/#/clusters](https://@@{instance_name}@@.@@{Helm_Kasten.nipio_ingress_domain}@@/k10/#/clusters)
