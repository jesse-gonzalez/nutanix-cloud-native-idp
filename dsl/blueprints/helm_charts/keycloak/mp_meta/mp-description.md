*Keycloak Helm Chart*

Keycloak provides user federation, strong authentication, user management, fine-grained authorization, and more.

### Chart Details

This chart will do the following:

- Deploy Keycloak  - [more info](https://www.keycloak.org/documentation)
- Configure Keycloak

#### Prerequisites:

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
- `Ingress-Nginx` - [more info](https://kubernetes.github.io/ingress-nginx/)
