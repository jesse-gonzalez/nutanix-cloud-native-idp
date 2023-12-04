

#### Connectivity Details

__OpenShift Connectivity:__

[https://console-openshift-console.apps.@@{ocp_hub_cluster_name}@@.@@{ocp_base_domain}@@](https://console-openshift-console.apps.@@{ocp_hub_cluster_name}@@.@@{ocp_base_domain}@@)


```bash
## kubectl / oc
oc login -u kubeadmin -p @@{Openshift Cluster Service.kube_admin_password}@@ https://api.@@{ocp_cluster_name}@@.@@{ocp_base_domain}@@:6443

## ansible_automation_pass:
kubectl get secret aap-hub-admin-password -o jsonpath='{.data.password}' -n ansible-automation-platform | base64 -d

## advanced_security_pass:
kubectl get secret central-htpasswd -o jsonpath='{.data.password}' -n stackrox | base64 -d
```
