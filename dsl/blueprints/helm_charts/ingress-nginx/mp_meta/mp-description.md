*Kubernetes Ingress Nginx Helm Chart*

ingress-nginx is an Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.

### Chart Details

This chart will do the following:

- Deploy Kubernetes Ingress Nginx - [more info](https://github.com/kubernetes/ingress-nginx/)

#### Prerequisites:

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
