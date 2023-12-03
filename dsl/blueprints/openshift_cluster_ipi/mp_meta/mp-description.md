*Red Hat Openshift* is is a unified platform to build, modernize, and deploy Kubernetes managed applications at scale.

This blueprint is used to build a `Red Hat Openshift Container Platform (RHOCP)` via the `Installer Provisioned Infrastructure (IPI)` deployment option.

It is also used to install and configure other `Red Hat` products such as `Advanced Cluster Management (ACM)`, `Ansible Automation Platform (AAP)`, `Advanced Cluster Security (ACS)`, `Openshift APIs for Data Protection (OADP)`, `Quay Enterprise Registry` and `Openshift GitOps` as a means of demonstrating integration with the suite of `Nutanix` services such as `Unified Storage (NUS)`, `Database (NDB)` and the `Acropolis Hypervisor (AHV)`.

`AWS Route 53` hosted zones and `Let's Encrypt` certificates are leveraged throughout to simplify multi cluster/site & environment access from desktop. **This is not recommended for production purposes.**

#### Prerequisites

- Prism Central >= pc.2022.6.0.1
- AOS >= 5.20.4 or >= 6.1.1.5
- Files >= 4.2.1
- Objects >= 3.6
- Era >= 2.4
- AHV Network with IPAM (min. 20 IPs avail.)
- Valid TLS certificate for Prism Central
  - `NOTE: Self-Service Runbooks can be leveraged to create Route53 DNS Records and Certs`
- AWS Route53 Domain Hosted Zone (i.e., ncnlabs.ninja) with IAM Access with CRUD Access
- Internal DNS Server / LDAP Domain (i.e., ntnxlabs.local)
- Existing Linux VM Endpoint (i.e., bastionws.ntnxlab.local)
- Red Hat Console Access w/ Pull Secret JSON

#### Hardware Requirement

Default configs are for `Production-Like` topology. Minimum required are total 9 nodes:

- 3 Control Plane nodes - each with 8 vCPU, 20 GiB RAM, 200 GiB Disk
- 3 Infra nodes - each with 8 vCPU, 24 GiB RAM, 200 GiB Disk
- 3 Worker nodes - each with 8 vCPU, 8 GiB RAM, 200 GiB Disk

#### Resources Installed and Configured

Beyond the Openshift Cluster being created, the following resources are installed/configured by default:

- Configure AWS Route53 Hosted Zone Resource Records for *.apps and api records
- Configure Ingress Router with TLS Certs
- Configure Infra Node Machine Set and Migrate Resources
- Configure Cluster Auto Scaler for both Infra and Worker Machine Set
- Configure Internal Image Registry with Nutanix Objects S3
- Configure Openshift Monitoring with User Workload and S3
- Confiugre Prometheus ServiceMonitors for Nutanix Object Store / Buckets
- Initiate & Configure Etcd Backup Cronjob
- Configure Nutanix AHV VM-VM Anti-Affinity

#### Default Operators Installed and Configured

- Configure DNS Forwarders on DNS Operator and OAUTH LDAP Provider
- Install Nutanix CSI Driver/Operator
- Configure Nutanix Volumes and Files Storage Classes
- Install Nutanix Database as a Service (NDB) Operator
- `Optional:` Install ACM Hub Operator and Configure MultiClusterHub and MultiClusterObservability with Thanos/S3
- `Optional:` Imports and Configures Secondary ACM Hub Managed Cluster
- `Optional:` Install Ansible Automation Platform Operator and Configure AutomationHub
- `Optional:` Install Advanced Cluster Security and Configures Central / Secured Cluster on Hub
- `Optional:` Install Openshift GitOps and Configures ArgoCD Instance on Hub
- Install OADP Backup Operator and Configure DataProtectionApplication / Restic with Objects S3

#### Lifecycle Actions

- Deploy Quay Registry via Operator with Objects S3 Backend
- Deploy Wordpress Stateful Demo App with Files/Volumes and OADP Restic Backups
- Deploy PostGreSQL Demo Database with TODO App via NDB operator
- Create New S3 Buckets on Nutanix Objects
- Create On-Demand Etcd Snapshot/Backup
