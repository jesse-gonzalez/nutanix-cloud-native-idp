
#### Connectivity Details

Now that you've provisioned your AKS cluster, you need to configure kubectl.

Run the following command from Console to retrieve the access credentials for your cluster and automatically configure `kubectl`.

`az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)`
