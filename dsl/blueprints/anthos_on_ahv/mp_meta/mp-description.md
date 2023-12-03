`Anthos` is a managed application platform that extends Google Cloud services and engineering practices to your environments so you can modernize apps faster and establish operational consistency across them.

#### Prerequisites

- `Nutanix:`
  - `Cluster:`
    - `AHV:` 20201105.1045 or later
    - `AOS:` 5.19.1 or later
    - `iSCSI` data service IP configured
    - `VLAN network` with `AHV IPAM` configured
  - `Prism Central:` 2020.11.0.1 or later
  - `Calm:`
    - `Version:` 3.0.0.2 or later
    - A `project` with `AHV` provider
- `Google Cloud:`
  - A project with `Owner` role
  - A `service account` - <https://console.cloud.google.com/iam-admin/serviceaccounts/create>
    - `Role:` Project Owner
    - A `private key:` JSON
- `Networking:`
  - `Internet connectivity`
  - `AHV IPAM:` Minimum 6 IP addresses available for the virtual machines
  - `Kubernetes:`
    - `Control plane VIP:` One IP address in the same network than virtual machines but not part of the AHV IPAM
    - `Ingress VIP:` One IP address in the same network than virtual machines but not part of the AHV IPAM. This IP must be part of the load balancing pool
    - `Load balancing pool:` Range of IP addresses in the same network than virtual machines but not part of the AHV IPAM. The Ingress VIP is included in this pool
    - `Pods network:` CIDR network with enough IP addresses, usually /16 and not sharing the same network than virtual machines or Kubernetes Services. If your containerized application must communicate with a system out of the Kubernetes cluster, make sure then this network doesn't overlap either with the external system network
    - `Services network:` CIDR network with enough IP addresses, usually /16 and not sharing the same network than virtual machines or Kubernetes Pods. If your containerized application must communicate with a system out of the Kubernetes cluster, make sure then this network doesn't overlap either with the external system network
- `Credentials:`
  - `Operating system:` you need a SSH key

  - `Prism Element:` an account, local or Active Directory, with *User Admin* role. This is for the CSI plugin configuration
#### Resources Installed:

The following resources are installed by default:

- `Anthos version:` bare metal 1.6.1 - <https://cloud.google.com/anthos/clusters/docs/bare-metal/1.6/concepts/about-bare-metal>
- `Type:` hybrid - <https://cloud.google.com/anthos/clusters/docs/bare-metal/1.6/installing/install-prep#hybrid_cluster_deployment>
- `Number of virtual machines:` 6
  - 1 x Admin
  - 3 x Control plane
  - 2 x Worker nodes
- `Virtual machine OS:` CentOS 8 GenericCloud - <https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.2.2004-20200611.2.x86_64.qcow2>
- `High availability:` yes
- `Load balancing:` yes
- `Ingress:` yes
- `Persistent storage:` yes
- `Proxy:` no
- `KubeVirt:` no
- `OpenID Connect:` no
- `Application logs/metrics:` no
