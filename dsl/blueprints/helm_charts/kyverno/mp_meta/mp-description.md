*Kyverno Helm Chart*

Kyverno is a Kubernetes Native Policy Management engine. It allows you to:

Manage policies as Kubernetes resources (no new language required.)
Validate, mutate, and generate resource configurations.
Select resources based on labels and wildcards.
View policy enforcement as events.
Scan existing resources for violations.

### Chart Details

This chart will do the following:

- Deploy Kyverno
- Configure policy to effectively mutate container images to include the imagepull secret name
- Configure policy to continuously synchronize docker registry secret across all namespaces

#### Prerequisites

- Existing Karbon Cluster
