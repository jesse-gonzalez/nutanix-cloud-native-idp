*Sonarqube Helm Chart*

Sonarqube is an open sourced code quality scanning tool.

### Chart Details

This chart will do the following:

- Deploy Sonarqube
- Exposes Sonarqube with Ingress-Nginx
#### Prerequisites:

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
- `Ingress-Nginx` - [more info](https://kubernetes.github.io/ingress-nginx/)
