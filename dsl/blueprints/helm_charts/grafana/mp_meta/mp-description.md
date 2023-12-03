*Grafana Helm Chart*

Grafana allows you to query, visualize, alert on and understand your metrics no matter where they are stored. Create, explore, and share dashboards with your team and foster a data driven culture.

### Chart Details

This chart will do the following:

- Deploy Grafana
- Exposes Grafana with Ingress-Nginx
- Configure Karbon Prometheus as Datasource

#### Prerequisites:

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
- `Ingress-Nginx` - [more info](https://kubernetes.github.io/ingress-nginx/)
