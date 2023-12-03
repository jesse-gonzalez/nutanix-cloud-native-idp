
echo -e "\nThese Applications can be accessed using either kubeadmin password or adminuser01 ldap account & password:"
echo -e "   ACM Multi-Cloud Console: https://$(kubectl get route -n open-cluster-management multicloud-console -o jsonpath='{.spec.host}')"
echo -e "   Openshift Console: https://$(kubectl get route console -n openshift-console -o jsonpath='{.spec.host}')"
echo -e "   Grafana MultiCluster Observability Console: https://$(kubectl get route central -n stackrox -o jsonpath='{.spec.host}')"

echo -e "\nAnsible Automation Platform: https://$(kubectl get route aap-hub -n $OPERATOR_NS -o jsonpath='{.spec.host}')"
echo -e "Ansible Password: $(kubectl get secret aap-hub-admin-password -o jsonpath='{.data.password}' -n $OPERATOR_NS | base64 -d)"

echo -e "\nRedHat Advanced Security Services Console: https://$(kubectl get route central -n stackrox -o jsonpath='{.spec.host}')"
echo -e "RedHat Advanced Security Services Password: $(kubectl get secret central-htpasswd -o jsonpath='{.data.password}' -n stackrox | base64 -d)"

echo -e "\nOpenshift GitOps ArgoCD Console: https://$(kubectl get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
echo -e "Openshift GitOps ArgoCD Password: $(oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-)"
