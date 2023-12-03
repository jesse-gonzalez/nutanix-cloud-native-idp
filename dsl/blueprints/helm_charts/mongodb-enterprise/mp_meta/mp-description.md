*MongoDB Enterprise Operator Helm Chart*

The MongoDB Enterprise Kubernetes Operator provides a container image for the MongoDB Agent in Ops Manager.

This allows you to manage and deploy MongoDB database clusters with full monitoring, backups, and automation provided by Ops Manager.

The Operator enables easy deploy of the following applications into Kubernetes clusters:

`MongoDB` - Replica Sets, Sharded Clusters and Standalones - with authentication, TLS and many more options.
`Ops Manager` - our enterprise management, monitoring and backup platform for MongoDB. The Operator can install and manage Ops Manager in Kubernetes for you. Ops Manager can manage MongoDB instances both inside and outside Kubernetes.

### Chart Details

This chart will do the following:

- Deploy MongoDB Enterprise Operator

#### Prerequisites

- Existing Karbon Cluster

The following services have been pre-configured:

- `MetalLB` - [more info](https://metallb.universe.tf/)
- `Cert-Manager` - [more info](https://cert-manager.io/docs/installation/kubernetes/)

#### Day 2 Actions

- Configure MongoDB OpsManager Cluster (+ Backend ApplicationDB ReplicaSet)
  - Expose MongoDB OpsManager via MetalLB Service LoadBalancer
- Configure MongoDB Standalone Instance
- Configure MongoDB ReplicaSet Cluster
- Configure MongoDB Sharded Cluster
