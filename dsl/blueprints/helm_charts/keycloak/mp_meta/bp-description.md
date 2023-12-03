



#### Connectivity Details

URL:
[http://@@{instance_name}@@.@@{Helm_Keycloak.nipio_ingress_domain}@@](http://@@{instance_name}@@.@@{Helm_Keycloak.nipio_ingress_domain}@@)

Username: admin

Temporary_Password can be found using the following:

`kubectl get secret --namespace keycloak keycloak -o jsonpath="{.data.admin-password}" | base64 --decode`
