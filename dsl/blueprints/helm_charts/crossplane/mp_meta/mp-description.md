*Crossplane Helm Chart*

Crossplane is an open source Kubernetes add-on that transforms your cluster into a universal control plane. Crossplane enables platform teams to assemble infrastructure from multiple vendors, and expose higher level self-service APIs for application teams to consume, without having to write any code.

Crossplane extends your Kubernetes cluster to support orchestrating any infrastructure or managed service. Compose Crossplane’s granular resources into higher level abstractions that can be versioned, managed, deployed and consumed using your favorite tools and existing processes.

### Chart Details

This chart will do the following:

- Deploy Certificate Manager  - [more info](https://cert-manager.io/docs/)
- Configure Self-Signed Cluster Issuer

#### Prerequisites:

- Existing Karbon Cluster
