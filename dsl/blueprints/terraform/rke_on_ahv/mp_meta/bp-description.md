
#### Connectivity Details

After deployment Terraform will fetch the kubeconfig file from the `Admin vm`. This file will be named `kube_config_cluster.yml`.

The cluster can be accessed by using the `KUBECONFIG` environment variable:

`export KUBECONFIG="kube_config_cluster.yml"`
