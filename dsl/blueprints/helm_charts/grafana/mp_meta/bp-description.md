
#### Connectivity Details

URL:
[https://@@{instance_name}@@.@@{Helm_Grafana.nipio_ingress_domain}@@](https://@@{instance_name}@@.@@{Helm_Grafana.nipio_ingress_domain}@@)

Default Access:
username: `admin`
password: `kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 -d && echo`
