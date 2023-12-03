"""
Openshift Container Platform - Cluster Deployment Blueprint

"""

import base64
import json
import os
from calm.dsl.builtins import *
from calm.dsl.config import get_context

ContextObj = get_context()
init_data = ContextObj.get_init_config()

## if ocp_pull_secret json exists in local config dir, use that, otherwise use environment variable from secrets.yaml
if file_exists(os.path.join(init_data["LOCAL_DIR"]["location"], "ocp_pull_secret.json")):
    OpenshiftPullSecret = read_local_file("ocp_pull_secret.json")
else:
    OpenshiftPullSecret = os.environ['OCP_PULL_SECRET_JSON']

## need to replace space with new line because make shell removes new lines from variables
NutanixKeyUser = os.environ['NUTANIX_KEY_USER']

if file_exists(os.path.join(init_data["LOCAL_DIR"]["location"], "nutanix_public_key")):
    NutanixPublicKey = read_local_file("nutanix_public_key")
else:
    NutanixPublicKey = os.environ['NUTANIX_PUBLIC_KEY']

if file_exists(os.path.join(init_data["LOCAL_DIR"]["location"], "nutanix_key")):
    NutanixKey = read_local_file("nutanix_key")
else:
    NutanixKey = "-----BEGIN OPENSSH PRIVATE KEY-----" + os.environ['NUTANIX_KEY'].split("KEY-----", 1)[1].split("-----END", 1)[0].replace(" ","\n") + "-----END OPENSSH PRIVATE KEY-----"

NutanixCred = basic_cred(
                    NutanixKeyUser,
                    name="Nutanix",
                    type="KEY",
                    password=NutanixKey,
                    default=True
                )

NutanixUser = os.environ['NUTANIX_USER']
NutanixPassword = os.environ['NUTANIX_PASS']

NutanixPasswordCred = basic_cred(
                    NutanixUser,
                    name="Nutanix Password",
                    type="PASSWORD",
                    password=NutanixPassword,
                    default=True
                )

PrismCentralUser = os.environ['PRISM_CENTRAL_USER']
PrismCentralPassword = os.environ['PRISM_CENTRAL_PASS']
PrismCentralCred = basic_cred(
                    PrismCentralUser,
                    name="Prism Central User",
                    type="PASSWORD",
                    password=PrismCentralPassword,
                    default=False
                )

EraUser = os.environ['ERA_USER']
EraPassword = os.environ['ERA_PASS']
EraCred = basic_cred(
                    EraUser,
                    name="Era User",
                    type="PASSWORD",
                    password=EraPassword,
                    default=False
                )

PrismElementUser = os.environ['PRISM_ELEMENT_USER']
PrismElementPassword = os.environ['PRISM_ELEMENT_PASS']
# PrismElementPassword = read_local_file("prism_element_password")
PrismElementCred = basic_cred(
                    PrismElementUser,
                    name="Prism Element User",
                    type="PASSWORD",
                    password=PrismElementPassword,
                    default=False
                )

EncrypedPrismCentralCreds = base64.b64encode(bytes(PrismCentralPassword, 'utf-8'))
EncrypedPrismElementCreds = base64.b64encode(bytes(PrismElementPassword, 'utf-8'))

DockerHubUser = os.environ['DOCKER_HUB_USER']
DockerHubPassword = os.environ['DOCKER_HUB_PASS']
DockerHubCred = basic_cred(
                    DockerHubUser,
                    name="Docker Hub User",
                    type="PASSWORD",
                    password=DockerHubPassword,
                    default=False
                )

LdapUser = os.environ['WINDOWS_DOMAIN_USER']
LdapPassword = os.environ['WINDOWS_DOMAIN_PASS']
LdapCred = basic_cred(
                    LdapUser,
                    name="Ldap User",
                    type="PASSWORD",
                    password=LdapPassword,
                    default=False
                )

ObjectsAccessKey = os.environ['OBJECTS_ACCESS_KEY']
ObjectsSecretKey = os.environ['OBJECTS_SECRET_KEY']
ObjectsCred = basic_cred(
                    ObjectsAccessKey,
                    name="Objects S3 Access Key",
                    type="PASSWORD",
                    password=ObjectsSecretKey,
                    default=False
                )

AwsAccessKeyId = os.environ['AWS_ACCESS_KEY_ID']
AwsSecretAccessKey = os.environ['AWS_SECRET_ACCESS_KEY']
AwsAccessCred = basic_cred(
                    AwsAccessKeyId,
                    name="AWS Access Key",
                    type="PASSWORD",
                    password=AwsSecretAccessKey,
                    default=False
                )

BastionHostEndpoint = os.getenv("BASTION_WS_ENDPOINT")

class OpenshiftCluster(Service):
    name = "Openshift Cluster Service"

    project_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    network_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    machine_network = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    era_cluster_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    prism_element_external_ip = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    prism_element_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    kube_admin_password = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    objects_buckets_list = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )

    @action
    def ConfigurePreRequisites(name="Configure PreRequisites"):
        CalmTask.Exec.escript(
            name="Create AWS Route53 Resource Records",
            filename="scripts/create/create_route53_dns.py"
        )
        CalmTask.SetVariable.escript(
            name="Get Prism Element UUID",
            filename="scripts/create/get_ahv_cluster_uuid.py",
            variables=["prism_element_uuid"]
        )
        CalmTask.SetVariable.escript(
            name="Get Prism Element External IP",
            filename="scripts/create/get_ahv_cluster_ext_ip.py",
            variables=["prism_element_external_ip"]
        )
        CalmTask.SetVariable.escript(
            name="Get Network UUID",
            filename="scripts/create/get_network_uuid.py",
            variables=["network_uuid"]
        )
        CalmTask.SetVariable.escript(
            name="Get Machine Network",
            filename="scripts/create/get_machine_network.py",
            variables=["machine_network"]
        )
        CalmTask.SetVariable.escript(
            name="Get Project UUID",
            filename="scripts/create/get_project_uuid.py",
            variables=["project_uuid"]
        )

    @action
    def CreateOpenshiftCluster(name="Provision Openshift Cluster via IPI"):
        CalmTask.Exec.ssh(
            name="Init Local Configs",
            filename="scripts/create/init_local_configs.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Cloud Credential Operator Util",
            filename="scripts/create/configure_ccoctl_creds.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Create Openshift Install Config YAML File",
            filename="scripts/create/create_openshift_cluster_yaml_config.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Create Openshift Cluster Manifests",
            filename= "scripts/create/create_openshift_cluster_manifests.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Create Openshift Cluster",
            filename= "scripts/create/create_openshift_cluster.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.SetVariable.ssh(
            name="Set Service Variables",
            filename="scripts/create/set_service_variables.sh",
            target=ref(OpenshiftCluster),
            cred=ref(NutanixCred),
            variables=["kube_admin_password"]
        )

    @action
    def ConfigureNutanixCSI(name="Configure Nutanix CSI Operator"):
        CalmTask.Exec.ssh(
            name="Configure Nutanix CSI Operator",
            filename= "scripts/create/configure_csi_operator.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Nutanix Files CSI StorageClasses",
            filename= "scripts/create/configure_files_sc.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureOpenshiftCluster(name="Configure Openshift Cluster"):
        CalmTask.Exec.ssh(
            name="Configure Forwarders on DNS Operator",
            filename= "scripts/create/configure_dns_operator.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Infra Node Machineset",
            filename= "scripts/create/configure_infra_machineset.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Cluster Wide Autoscaler",
            filename= "scripts/create/configure_cluster_autoscaler.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Cluster Autoscaler on Worker MachineSet",
            filename= "scripts/create/configure_worker_machineset_autoscaler.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Cluster Autoscaler on Infra MachineSet",
            filename= "scripts/create/configure_infra_machineset_autoscaler.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Generate TLS Certs via ACME client",
            filename= "scripts/create/generate_tls_certs.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Replace Default TLS Certs for Ingress Router",
            filename= "scripts/create/configure_ingress_tls_certs.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Internal Image Registry Persistence",
            filename= "scripts/create/configure_image_registry_persistence.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Red Hat Openshift Monitoring Persistence",
            filename= "scripts/create/configure_openshift_monitoring_persistence.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Nutanix Objects Prometheus Exporter",
            filename= "scripts/create/configure_objects_prometheus_exporter.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure LDAP OAuth Provider",
            filename= "scripts/create/configure_oauth_ldap_integration.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureNutanixAHV(name="Configure Nutanix AHV Hypervisor"):
        CalmTask.Exec.ssh(
            name="Configure Openshift VM Anti_Affinity",
            filename= "scripts/create/configure_ahv_vm_anti_affinity.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureNutanixDatabase(name="Configure Nutanix NDB Operator"):
        CalmTask.SetVariable.escript(
            name="Get Era Cluster UUID",
            filename="scripts/create/get_era_cluster_uuid.py",
            variables=["era_cluster_uuid"]
        )
        CalmTask.Exec.ssh(
            name="Configure Nutanix NDB Operator",
            filename= "scripts/create/configure_ndb_operator.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureAdvanceClusterManagement(name="Configure Advanced Cluster Management"):
        CalmTask.Exec.ssh(
            name="Configure RedHat Advanced Cluster Management",
            filename= "scripts/create/enable_redhat_advanced_cluster_management.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )       
        CalmTask.Exec.ssh(
            name="Configure RedHat Advanced Cluster Management Observability with Thanos",
            filename= "scripts/create/configure_thanos_mc_observability.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Import ACM Managed OCP Cluster",
            filename= "scripts/create/import_acm_managed_cluster.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureAnsiblePlatformAutomation(name="Configure Ansible Platform Automation"):
        CalmTask.Exec.ssh(
            name="Configure RedHat Ansible Automation Platform",
            filename= "scripts/create/configure_ansible_automation_operator.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureAdvancedClusterSecurity(name="Configure Advanced Cluster Security"):
        CalmTask.Exec.ssh(
            name="Configure RedHat Advanced Cluster Security Operator",
            filename= "scripts/create/configure_rhacs_operator.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure RedHat ACS Central Cluster",
            filename= "scripts/create/configure_rhacs_central_instance.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure RedHat ACS Secured Cluster",
            filename= "scripts/create/configure_rhacs_secured_cluster.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureOpenshiftGitOps(name="Configure Openshift GitOps"):
        CalmTask.Exec.ssh(
            name="Configure RedHat Openshift GitOps Operator",
            filename= "scripts/create/configure_gitops_operator.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure ArgoCd Instance",
            filename= "scripts/create/configure_gitops_argocd_instance.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureDataProtection(name="Configure Data Protection"):
        CalmTask.Exec.ssh(
            name="Configure RedHat OADP Operator",
            filename= "scripts/create/configure_oadp_operator.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Etcd Backup Cronjob",
            filename= "scripts/create/configure_etcd_backups.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def OutputAccessConnectivityInfo(name="Output Access Connectivity Info"):
        CalmTask.Exec.ssh(
            name="Output Access and Connectivity Info",
            filename= "scripts/create/output_access_connectivity_info.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )


    @action
    def DeleteOpenshiftCluster(name="Delete Openshift Cluster"):
        CalmTask.Exec.ssh(
            name="Remove Openshift Cluster from VM Anti_Affinity Groups",
            filename="scripts/delete/delete_ahv_vm_anti_affinity.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Delete NDB Demo Database",
            filename="scripts/delete/delete_todo_ndb_demo_instance.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Openshift Cluster Delete",
            filename="scripts/delete/delete_openshift_cluster.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.escript(
            name="Delete AWS Route53 Resource Records",
            filename="scripts/delete/delete_route53_dns.py"
        )

        # CalmTask.Exec.escript(
        #     name="Add Categories to Openshift Nodes",
        #     filename="scripts/common/add_category_to_nodes.py",
        # )


    # @action
    # def InitAutoscalerStressSim(name="Init AutoScaler Stress Sim"):
    #     CalmTask.Exec.ssh(
    #         name="Deploy CPU Hog Application",
    #         filename="scripts/day_two_actions/init_node_scalability_load_test/deploy_cpu_hog.sh",
    #         cred=NutanixCred
    #     )
    #     CalmTask.Exec.ssh(
    #         name="Deploy HPA Stress Application",
    #         filename="scripts/day_two_actions/init_node_scalability_load_test/deploy_stress_app.sh",
    #         cred=NutanixCred
    #     )

    # @action
    # def CleanupAutoscalerStressSim(name="Cleanup AutoScaler Stress Sim"):
    #     CalmTask.Exec.ssh(
    #         name="Cleanup All Stress Sim",
    #         filename="scripts/day_two_actions/init_node_scalability_load_test/decom_stress_all.sh",
    #         cred=NutanixCred
    #     )

    @action
    def CreateNutanixS3Buckets(name="Create Buckets within Nutanix Objects"):
        CalmTask.Exec.escript(
            name="Update Nutanix Objects Buckets",
            filename="scripts/update/create_objects_bucket.py"
        )

    @action
    def CreateEtcdBackup(name="Create Etcd Snapshot"):
        CalmTask.Exec.ssh(
            name="Create Etcd Snapshot",
            filename="scripts/update/create_etcd_backup.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def DeployWordpressDemo(name="Deploy Wordpress Stateful Demo"):
        CalmTask.Exec.ssh(
            name="Deploy Wordpress Stateful Demo",
            filename="scripts/update/deploy_wordpress_stateful_demo.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Wordpress OADP Restic Backups",
            filename="scripts/update/configure_wordpress_oadp_restic_backup.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    @action
    def DeployNutanixDBDemo(name="Deploy Nutanix NDB TODO Demo"):
        CalmTask.Exec.ssh(
            name="Deploy Nutanix NDB Instance with TODO App",
            filename="scripts/update/configure_todo_ndb_demo_instance.sh",
            target=ref(OpenshiftCluster),
            cred=NutanixCred
        )

    # @action
    # def ConfigureQuayImageRegistry(name="Configure Quay Image Registry"):
    #     CalmTask.Exec.ssh(
    #         name="Configure Quay Registry Operator",
    #         filename= "scripts/update/configure_quay_registry_operator.sh",
    #         target=ref(OpenshiftCluster),
    #         cred=NutanixCred
    #     )
    #     CalmTask.Exec.ssh(
    #         name="Configure Quay Registry Cluster Instance",
    #         filename= "scripts/update/configure_quay_registry_instance.sh",
    #         target=ref(OpenshiftCluster),
    #         cred=NutanixCred
    #     )

class OpenshiftClusterPackage(Package):
    name = "Openshift Installer Package"

    services = [ref(OpenshiftCluster)]

    @action
    def __install__():
      OpenshiftCluster.ConfigurePreRequisites(name="Configure PreRequisites")
      OpenshiftCluster.CreateOpenshiftCluster(name="Provision Openshift Cluster via IPI")
      OpenshiftCluster.ConfigureNutanixCSI(name="Configure Nutanix CSI Operator")
      OpenshiftCluster.ConfigureOpenshiftCluster(name="Configure Openshift Cluster")
      OpenshiftCluster.ConfigureNutanixAHV(name="Configure Nutanix AHV Hypervisor")
      ##OpenshiftCluster.ConfigureNutanixDatabase(name="Configure Nutanix NDB Operator")
      ##OpenshiftCluster.ConfigureAdvanceClusterManagement(name="Configure Advanced Cluster Management")
      ##OpenshiftCluster.ConfigureAnsiblePlatformAutomation(name="Configure Ansible Platform Automation")
      ##OpenshiftCluster.ConfigureAdvancedClusterSecurity(name="Configure Advanced Cluster Security")
      ##OpenshiftCluster.ConfigureOpenshiftGitOps(name="Configure Openshift GitOps")
      OpenshiftCluster.ConfigureDataProtection(name="Configure Data Protection")
      OpenshiftCluster.OutputAccessConnectivityInfo(name="Output Access Connectivity Info")

    @action
    def __uninstall__():
      OpenshiftCluster.DeleteOpenshiftCluster(name="Delete Openshift Cluster")


class OpenshiftClusterVM(Substrate):

    name = "Openshift Admin Jumpbox"

    os_type = "Linux"
    provider_type = "EXISTING_VM"
    provider_spec = read_provider_spec(os.path.join("image_configs", "bastionctl_workstation_provider_spec.yaml"))

    provider_spec.spec["address"] = BastionHostEndpoint

    readiness_probe = readiness_probe(
        connection_type="SSH",
        disabled=False,
        retries="15",
        connection_port=22,
        address=BastionHostEndpoint,
        delay_secs="60",
        credential=ref(NutanixCred),
    )

class OpenshiftClusterDeployment(Deployment):
    """
    OpenshiftCluster deployment
    """

    packages = [ref(OpenshiftClusterPackage)]
    substrate = ref(OpenshiftClusterVM)
    min_replicas = "1"
    max_replicas = "1"


class Default(Profile):
    """
    Nutanix AHV Application profile.
    """

    deployments = [OpenshiftClusterDeployment]
    nutanix_public_key = CalmVariable.Simple.Secret(
        NutanixPublicKey,
        label="Nutanix Public Key",
        is_hidden=True,
        description="SSH public key for the Nutanix user."
    )
    ocp_cluster_name = CalmVariable.Simple(
        "",
        label="Openshift Cluster Name",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        regex="^([a-zA-Z0-9_-]{0,24})$",
        validate_regex=True,
        description="Name of the Openshift cluster to be created"
    )
    ocp_hub_cluster_name = CalmVariable.Simple(
        os.getenv("OCP_HUB_CLUSTER_NAME"),
        label="Openshift Hub Cluster Name",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        regex="^([a-zA-Z0-9_-]{0,24})$",
        validate_regex=True,
        description="Name of the Openshift Hub cluster running Advanced Cluster Management"
    )
    nutanix_files_nfs_fqdn = CalmVariable.Simple(
        os.getenv("NUTANIX_FILES_NFS_FQDN"),
        label="Nutanix Files NFS Server FQDN",
        is_mandatory=True,
        runtime=True,
        description="Nutanix Files NFS Server FQDN. i.e., BootcampFS.ntnxlab.local"
    )
    nutanix_files_nfs_export = CalmVariable.Simple(
        os.getenv("NUTANIX_FILES_NFS_EXPORT"),
        label="Nutanix Files NFS Export",
        is_mandatory=True,
        runtime=True,
        description="Nutanix Files NFS Export. i.e., kalm-main-nfs"
    )
    ocp_base_domain = CalmVariable.Simple(
        os.getenv("OCP_BASE_DOMAIN"),
        label="OCP Base Domain Name",
        is_mandatory=True,
        runtime=True,
        description="OCP Base Domain name used as suffix for FQDN. Entered similar to 'ncnlabs.ninja'."
    )
    domain_name = CalmVariable.Simple(
        os.getenv("DOMAIN_NAME"),
        label="Internal LDAP/DNS Domain Name",
        is_mandatory=True,
        runtime=True,
        description="Domain name used as suffix for FQDN. Entered similar to 'ntnxlab.local'."
    )
    dns_server = CalmVariable.Simple(
        os.getenv("DNS"),
        label="External DNS Resolver",
        is_mandatory=True,
        runtime=True,
        description="External DNS Resolver IP used within CoreDNS."
    )
    pc_instance_port = CalmVariable.Simple.string(
        os.getenv("PC_PORT"),
        label="Prism Central Port Number",
        is_mandatory=True,
        runtime=True,
        description="Port Number of Prism Central Instance."
    )
    ocp_ntnx_pc_dns_fqdn = CalmVariable.Simple.string(
        os.getenv("OCP_NTNX_PC_DNS_FQDN"),
        label="Prism Central FQDN endpoint",
        is_mandatory=True,
        runtime=True,
        description="FQDN DNS endpoint of the Prism Central instance."
    )
    pc_instance_ip = CalmVariable.Simple.string(
        os.getenv("NTNX_PC_IP"),
        label="Prism Central IP Address",
        is_mandatory=True,
        runtime=True,
        description="IP address of the Prism Central instance."
    )
    era_vm_ip = CalmVariable.Simple.string(
        os.getenv("ERA_VM_IP"),
        label="ERA VM IP Address",
        is_mandatory=True,
        runtime=True,
        description="IP address of the Era NDB instance."
    )
    infra_machineset_count = CalmVariable.Simple(
        "3",
        label="Default Number of Infra Machines",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Default Number of Infra Machines. Can be easily scaled by increasing machineset replicas",
    )
    worker_machineset_count = CalmVariable.Simple(
        "3",
        label="Default Number of Worker Machines",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Default Number of Worker Machines. Can be easily scaled by increasing machineset replicas",
    )
    control_plane_count = CalmVariable.WithOptions(
        ["1", "3"],
        label="Number of Control Plane Nodes",
        default="3",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="Number of control plane nodes to deploy. Options are 1 or 3",
    )
    storage_container_name = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename="scripts/create/get_storage_containers.py",
        ),
        label="Storage Container",
        is_mandatory=True,
        is_hidden=False,
        description="Storage container for Persistent Volume Claims",
    )
    network = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename= "scripts/create/get_networks.py",
        ),
        label="Network",
        is_mandatory=True,
        is_hidden=False,
        description="Network for the Openshift Kubernetes nodes.",
    )
    nutanix_ahv_cluster = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename="scripts/create/get_nutanix_ahv_clusters.py",
        ),
        label="Cluster",
        is_mandatory=False,
        is_hidden=False,
        description="AHV cluster to run Openshift Kubernetes Nodes on.",
    )
    api_ipv4_vip = CalmVariable.Simple(
        "",
        label="Openshift API Vip",
        regex="^(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.?){4})$|^(\s{1})$",
        validate_regex=True,
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="The external ipv4 address will be used to access API server in api.<sub-domain>. i.e., 10.38.16.57 or 10.38.16.120 or 10.38.16.184 or 10.38.20.248",
    )
    wildcard_ingress_ipv4_vip = CalmVariable.Simple(
        "",
        label="Openshift Apps Ingress VIP",
        regex="^(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.?){4})$|^(\s{1})$",
        validate_regex=True,
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="The external ipv4 address used for wildcard ingress domain i.e,. *.apps.<sub-domain>. i.e., 10.38.16.58 or 10.38.16.121 or 10.38.16.185 or 10.38.20.249",
    )
    enable_redhat_advanced_cluster_management = CalmVariable.WithOptions(
        ["true", "false"],
        label="Enable RedHat Advanced Cluster Management",
        default="false",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="This will configure redhat advanced cluster management",
    )
    import_ocp_managed_cluster = CalmVariable.WithOptions(
        ["true", "false"],
        label="Import OCP Managed Cluster into ACM",
        default="true",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="This will import OCP cluster into target OCP-HUB",
    )
    enc_pc_creds = CalmVariable.Simple(
        EncrypedPrismCentralCreds.decode("utf-8"),
        is_mandatory=True,
        is_hidden=True,
        runtime=False,
    )

    enc_pe_creds = CalmVariable.Simple(
        EncrypedPrismElementCreds.decode("utf-8"),
        is_mandatory=True,
        is_hidden=True,
        runtime=False,
    )
    ocp_pull_secret = CalmVariable.Simple.Secret(
        OpenshiftPullSecret,
        label="Openshift Pull Secret Json",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Copy and Paste from RedHat Portal as one liner.",
    )
    objects_store_dns_fqdn = CalmVariable.Simple(
        os.getenv("OBJECTS_STORE_DNS_FQDN"),
        label="Objects Store Public DNS Endpoint", 
        description="Public DNS FQDN of Nutanix Objects Store",
        is_mandatory=True,
        runtime=True
    )

    @action
    def CreateNutanixS3Buckets(name="Create Buckets in Object Store"):
        """
    Create Buckets in Object Store
        """
        objects_buckets_list = CalmVariable.Simple(
            "", 
            label="Objects Bucket List", 
            description="List of Buckets to Create in Nutanix Objects",
            is_mandatory=True,
            runtime=True
        )
        objects_store_dns_fqdn = CalmVariable.Simple(
            os.getenv("OBJECTS_STORE_PUBLIC_IP"),
            label="Objects Store Public DNS Endpoint", 
            description="Public DNS FQDN of Nutanix Objects Store",
            is_mandatory=True,
            runtime=True
        )

        OpenshiftCluster.CreateNutanixS3Buckets(name="Create Buckets in Object Store")
    
    @action
    def CreateEtcdBackup(name="Create Etcd Snapshot"):
        """
    Create Etcd Snapshot
        """

        OpenshiftCluster.CreateEtcdBackup(name="Create Etcd Snapshot")

    # @action
    # def ConfigureQuayImageRegistry(name="Configure Quay Image Registry"):
    #     """
    # Deploy & Configure Quay Image Registry
    #     """

    #     OpenshiftCluster.ConfigureQuayImageRegistry(name="Configure Quay Image Registry")

    @action
    def DeployWordpressDemo(name="Deploy Stateful Wordpress HA Demo"):
        """
    Deploy Wordpress Demo
        """

        OpenshiftCluster.DeployWordpressDemo(name="Deploy Stateful Wordpress HA Demo")

    @action
    def DeployNutanixDBDemo(name="Deploy TODO with NDB PostgreSql Demo"):
        """
    Deploy TODO with NDB PostgreSql Demo
        """

        OpenshiftCluster.DeployNutanixDBDemo(name="Deploy TODO with NDB PostgreSql Demo")


    # @action
    # def InitAutoscalerStressSim(name="Init AutoScaler Stress Sim"):
    #     """
    # Init AutoScaler Stress Sim
    #     """

    #     OpenshiftCluster.InitAutoscalerStressSim(name="Init AutoScaler Stress Sim")


    # @action
    # def CleanupAutoscalerStressSim(name="Cleanup AutoScaler Stress Sim"):
    #     """
    # Cleanup AutoScaler Stress Sim
    #     """

    #     OpenshiftCluster.CleanupAutoscalerStressSim(name="Cleanup CPU Hog AutoScaler Sim")

class OpenshiftClusterDeploy(Blueprint):
    """
### Openshift Cluster Deployment Blueprint
    """

    profiles = [Default]
    substrates = [
            OpenshiftClusterVM
            ]
    services = [
            OpenshiftCluster
            ]
    packages = [
            OpenshiftClusterPackage
            ]
    credentials = [
            NutanixCred,
            NutanixPasswordCred,
            PrismCentralCred,
            PrismElementCred,
            DockerHubCred,
            LdapCred,
            ObjectsCred,
            AwsAccessCred,
            EraCred,
            ]


def main():
    print(OpenshiftClusterDeploy.json_dumps(pprint=True))


if __name__ == "__main__":
    main()
