*JFrog Container Registry Helm Chart*

Universal Repository Manager supporting all major packaging formats, build tools and CI servers.

### Chart Details

This chart will do the following:

- Deploy JFrog Container Registry
- Optionally expose Artifactory with Wildcard Domain Ingress
- Configure Docker and Helm Local Repos (i.e., docker-dev-local,helm-dev-local)
- Configure Docker and Helm Virtual Repos (i.e., docker,helm)
- Configure Private Registry on Karbon Cluster

#### Prerequisites:

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
- `Ingress-Nginx` - [more info](https://kubernetes.github.io/ingress-nginx/)
