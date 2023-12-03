*OpenCost*

`OpenCost` models give teams visibility into current and historical Kubernetes spend and resource allocation. These models provide cost transparency in Kubernetes environments that support multiple applications, teams, departments, etc.

Born out of the `Kubecost` project, `OpenCost` introduces a new community-driven specification and accompanying implementation to solve this monitoring challenge in any Kubernetes environment above 1.8.

Here is a summary of features enabled:

- Real-time cost allocation by Kubernetes service, deployment, namespace, label, statefulset, daemonset, pod, and container
- Dynamic asset pricing enabled by integrations with AWS, Azure, and GCP billing APIs
- Supports on-prem k8s clusters with custom pricing sheets
- Allocation for in-cluster resources like CPU, GPU, memory, and persistent volumes.
- Allocation for AWS & GCP out-of-cluster resources like RDS instances and S3 buckets with key (optional)
- Easily export pricing data to Prometheus with /metrics endpoint (learn more)
- Free and open source distribution (Apache2 license)

### Chart Details

This chart will do the following:

- Deploy Kubecost Opencost
- Exposes Jenkins with Ingress-Nginx
- Configure TLS via Certificate Manager

#### Prerequisites

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
- `Ingress-Nginx` - [more info](https://kubernetes.github.io/ingress-nginx/)