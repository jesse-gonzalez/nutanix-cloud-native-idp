
#### Connectivity Details

URL:
[https://@@{instance_name}@@.@@{Helm_GitLab.nipio_ingress_domain}@@](https://@@{instance_name}@@.@@{Helm_GitLab.nipio_ingress_domain}@@)

#### First Login Details

Username: `root`

Initial Root Password can be found using the following:

`kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d ; echo`