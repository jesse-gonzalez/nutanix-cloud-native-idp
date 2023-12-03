*GitLab CE Helm Chart*

GitLab is a web-based Git repository that provides free open and private repositories, issue-following capabilities, and wikis.

### Chart Details

This chart will do the following:

- Deploy GitLab
- Exposes GitLab with Ingress-Nginx

#### Prerequisites:

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)
- `Ingress-Nginx` - [more info](https://kubernetes.github.io/ingress-nginx/)
