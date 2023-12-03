
#### Connectivity Details

Once deployed, the cluster is registered in `Anthos` but `GKE` is not logged in until you use the token for the service account created in Kubernetes. From your computer terminal run the following commands copying the token and using it in the GKE console (the service account name may vary depending if you changed the default value):

```bash
SECRET_NAME=$(kubectl get serviceaccount google-cloud-console -o jsonpath='{$.secrets[0].name}')
kubectl get secret ${SECRET_NAME} -o jsonpath='{$.data.token}' | base64 --decode
```
