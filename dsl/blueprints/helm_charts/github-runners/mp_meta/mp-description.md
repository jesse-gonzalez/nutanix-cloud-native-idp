*GitHub Actions Runners Helm Chart*

A self-hosted runner is a system that you deploy and manage to execute jobs from GitHub Actions on GitHub.com.

Self-hosted runners offer more control of hardware, operating system, and software tools than GitHub-hosted runners provide. With self-hosted runners, you can create custom hardware configurations that meet your needs with processing power or memory to run larger jobs, install software available on your local network, and choose an operating system not offered by GitHub-hosted runners. Self-hosted runners can be physical, virtual, in a container, on-premises, or in a cloud.

You can add self-hosted runners at various levels in the management hierarchy:

- Repository-level runners are dedicated to a single repository.
- Organization-level runners can process jobs for multiple repositories in an organization.
- Enterprise-level runners can be assigned to multiple organizations in an enterprise account.

[About Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)

### Chart Details

This chart will do the following:

- Deploy Certificate Manager  - [more info](https://cert-manager.io/docs/)
- Configure Self-Signed Cluster Issuer

#### Prerequisites:

- Existing Karbon Cluster
