*Kasten K10 by Veeam Helm Chart*

Kasten’s K10 data management platform, purpose-built for Kubernetes, provides backup and restore, disaster recovery, and mobility of Kubernetes applications.

For Additional Details, See: https://blog.kasten.io/protect-cloud-native-appdata-kasten-k10-nutanix-karbon

### Chart Details

This chart will do the following:

- Deploy Kasten K10 Data Management Platform
- Exposes Kasten K10 with Ingress-Nginx

#### Prerequisites:

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
- `Ingress-Nginx` - [more info](https://kubernetes.github.io/ingress-nginx/)
