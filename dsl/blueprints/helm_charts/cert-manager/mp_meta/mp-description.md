*Cert-Manager Helm Chart*

cert-manager is a native Kubernetes certificate management controller. It can help with issuing certificates from a variety of sources, such as Let’s Encrypt, HashiCorp Vault, Venafi, a simple signing key pair, or self signed.

It will ensure certificates are valid and up to date, and attempt to renew certificates at a configured time before expiry.

### Chart Details

This chart will do the following:

- Deploy Certificate Manager  - [more info](https://cert-manager.io/docs/)
- Configure Self-Signed Cluster Issuer

#### Prerequisites:

- Existing Karbon Cluster
