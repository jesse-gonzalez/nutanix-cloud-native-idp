Deploy *Azure AKS* Kubernetes clusters using *Terraform*

The Terraform Manifest are sourced from the following Git repo, whereby you can find additional code to enhance your experience with deploying a Rancher RKE cluster on top of AHV using Terraform:

[https://github.com/hashicorp/learn-terraform-provision-aks-cluster](https://github.com/hashicorp/learn-terraform-provision-aks-cluster)

More information can be found here: [https://learn.hashicorp.com/tutorials/terraform/aks](https://learn.hashicorp.com/tutorials/terraform/aks)

#### Hardware Requirement:

Terraform will deploy 2 node AKS cluster on default VPC using Terraform:

```
resource "azurerm_kubernetes_cluster" "default" {

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  ....

```

#### Inputs:

appId  = "Azure Kubernetes Service Cluster service principal"
password = "Azure Kubernetes Service Cluster password"

To create Azure AD Service Principal from command line, see tutorial (link above) or follow command below:

```
$ az ad sp create-for-rbac
```

#### Lifecycle:

- Deploy AKS cluster
- Add AKS worker nodes
- Delete AKS worker nodes
- Delete AKS cluster
