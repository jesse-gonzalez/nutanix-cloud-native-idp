Deploy *Rancher RKE* Kubernetes clusters on *Nutanix AHV* using *Terraform*

The Terraform Manifest are sourced from the following Git repo, whereby you can find additional code to enhance your experience with deploying a Rancher RKE cluster on top of AHV using Terraform:

[https://github.com/yannickstruyf3/rke-on-ahv](https://github.com/yannickstruyf3/rke-on-ahv)

More information on Rancher RKE can be found here: [https://rancher.com/docs/rke/latest/en/](https://rancher.com/docs/rke/latest/en/)

#### Hardware Requirement:

Terraform will deploy 6 AHV virtual machines based on CentOS 8 by default:

- 1 Admin VM
- 3 VMs with etcd and controlplane role
- 2 VMs with worker role

Note: A CentOS 8 image will be uploaded automatically

The Nutanix CSI driver will also be deployed with a Default Storage Class to create persistent volumes on Nutanix Volumes

#### Lifecycle:

- Deploy RKE cluster
- Add RKE worker nodes
- Delete RKE worker nodes (force-removal of nodes, to be modified in future versions)
- Delete RKE cluster
