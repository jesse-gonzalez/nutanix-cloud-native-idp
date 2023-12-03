"""
CALM DSL Karbon Cluster Deployment Blueprint

"""

import base64
import json
import os
from calm.dsl.builtins import *
from calm.dsl.config import get_context

ContextObj = get_context()
init_data = ContextObj.get_init_config()

NutanixKeyUser = os.environ['NUTANIX_KEY_USER']
#NutanixPublicKey = read_local_file("nutanix_public_key")
#NutanixKey = read_local_file("nutanix_key")

## need to replace space with new line because make shell removes new lines from variables
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

# Centos74_Image = vm_disk_package(
#                     name="centos7_generic",
#                     config_file="image_configs/centos74_disk.yaml"
#                 )

BastionHostEndpoint = os.getenv("BASTION_WS_ENDPOINT")

class KarbonCluster(Service):
    name = "Karbon Cluster Service"

    karbon_cluster_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    account_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
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
    prism_element_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    worker_config_node_pool_name = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    task_uuid = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    addtl_worker_count = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    less_worker_count = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    worker_node_pool_count = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )
    package_version = CalmVariable.Simple(
        "",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description=""
    )


    @action
    def CreateKarbonCluster(name="Create Karbon Cluster"):
        CalmTask.SetVariable.escript(
            name="Get Prism Element UUID",
            filename="scripts/create_k8s_cluster/get_ahv_cluster_uuid.py",
            variables=["prism_element_uuid"]
        )
        CalmTask.SetVariable.escript(
            name="Get Network UUID",
            filename="scripts/create_k8s_cluster/get_network_uuid.py",
            variables=["network_uuid"]
        )
        CalmTask.Exec.ssh(
            name="Create Karbon JSON Config",
            filename="scripts/create_k8s_cluster/create_karbon_cluster_json_config.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Create Karbon K8s Cluster",
            filename= "scripts/create_k8s_cluster/create_karbon_k8s_cluster.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Monitor Karbon K8s Cluster Creation",
            filename= "scripts/create_k8s_cluster/monitor_karbon_cluster_build.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Advanced Karbon Cluster Management",
            filename= "scripts/create_k8s_cluster/enable_karbon_management.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Check Build State",
            filename= "scripts/create_k8s_cluster/check_karbon_cluster_build_state.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Configure Multi Cluster Kubectl",
            filename= "../../_common/k8s/scripts/configure_kubectl_multi-cluster.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )
        CalmTask.SetVariable.escript(
            name="Get Cluster Worker Pool Config",
            filename="scripts/common/get_worker_node_pool_name.py",
            variables=["worker_config_node_pool_name"]
        )
        CalmTask.Exec.escript(
            name="Add Karbon_Workers Category to Worker Nodes",
            filename="scripts/common/add_category_to_workers.py",
        )
        CalmTask.Exec.ssh(
            name="Configure CoreDNS with External DNS Resolver",
            filename="../../_common/karbon/scripts/configure_coredns_ext_dns.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def InstallKyverno(name="Install Kyverno"):

        CalmTask.Exec.ssh(
            name="Install Kyverno to Synchronize Image Pull Secrets",
            filename="scripts/create_k8s_cluster/install_kyverno.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def InstallMetalLB(name="Install MetalLB"):

        CalmTask.Exec.ssh(
            name="Install MetalLB Kubernetes Manifests",
            filename="scripts/create_k8s_cluster/install_metallb.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def InstallMetricsServer(name="Install Metrics Server"):

        CalmTask.Exec.ssh(
            name="Install Metrics Server",
            filename="scripts/create_k8s_cluster/install_metrics_server.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def InstallKubernetesDashboard(name="Install Kubernetes Dashboard"):

        CalmTask.Exec.ssh(
            name="Kubernetes Dashboard Installation",
            filename="scripts/create_k8s_cluster/install_k8s_dashboard.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def InstallCertManager(name="Install Certificate Manager"):

        CalmTask.Exec.ssh(
            name="Install Certificate Manager Helm Chart",
            filename="scripts/create_k8s_cluster/install_cert_manager.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def InstallIngressNginx(name="Install Ingress Nginx"):

        CalmTask.Exec.ssh(
            name="Install Ingress Nginx Helm Chart",
            filename="scripts/create_k8s_cluster/install_ingress_nginx.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureK8sServiceAccount(name="Configure K8s Service Account"):
        CalmTask.Exec.ssh(
            name="Configure K8s Service Account",
            filename="../../_common/k8s/scripts/configure-sa-kubeconfig.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def ConfigureDynamicNFS(name="Configure Nutanix Files Storage Classes"):
        CalmTask.Exec.ssh(
            name="Configure Nutanix Files Storage Classes",
            filename="../../_common/karbon/scripts/configure_files_sc.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def DeleteKarbonCluster(name="Delete Karbon Cluster"):
        CalmTask.Exec.ssh(
            name="Disable Karbon Management on Cluster",
            filename="scripts/create_k8s_cluster/disable_karbon_management.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Karbon Cluster Delete",
            filename="scripts/create_k8s_cluster/delete_karbon_cluster.sh",
            target=ref(KarbonCluster),
            cred=NutanixCred
        )

    @action
    def AddWorkers(name="Add Workers"):
        CalmTask.SetVariable.escript(
            name="Get Cluster Worker Pool Config",
            filename="scripts/common/get_worker_node_pool_name.py",
            variables=["worker_config_node_pool_name"]
        )
        CalmTask.Exec.escript(
            name="Validate Add Worker Request",
            filename="scripts/day_two_actions/add_worker_nodes/validate_add_worker_request.py"
        )
        CalmTask.SetVariable.escript(
            name="Add Worker Nodes",
            filename="scripts/day_two_actions/add_worker_nodes/add_karbon_worker_node.py",
            variables=["task_uuid"]
        )
        CalmTask.Exec.escript(
            name="Monitor Karbon Add Node Task Status",
            filename="scripts/common/monitor_karbon_task_status.py",
        )
        CalmTask.Exec.escript(
            name="Add Karbon_AutoScaler Category to Worker Nodes",
            filename="scripts/common/add_category_to_workers.py",
        )

    @action
    def RemoveWorkers(name="Remove Workers"):
        CalmTask.SetVariable.escript(
            name="Get Cluster Worker Pool Config",
            filename="scripts/common/get_worker_node_pool_name.py",
            variables=["worker_config_node_pool_name"]
        )
        CalmTask.Exec.escript(
            name="Validate Remove Worker Request",
            filename="scripts/day_two_actions/remove_worker_nodes/validate_remove_worker_request.py"
        )
        CalmTask.SetVariable.escript(
            name="Remove Worker Nodes",
            filename="scripts/day_two_actions/remove_worker_nodes/remove_karbon_worker_node.py",
            variables=["task_uuid"]
        )
        CalmTask.Exec.escript(
            name="Monitor Karbon Remove Node Task Status",
            filename="scripts/common/monitor_karbon_task_status.py",
        )

    @action
    def UpgradeKubernetes(name="Upgrade Kubernetes"):
        CalmTask.SetVariable.escript(
            name="Get Karbon Cluster UUID",
            filename="scripts/common/get_karbon_cluster_uuid.py",
            variables=["karbon_cluster_uuid"]
        )
        CalmTask.SetVariable.escript(
            name="Upgrade Kubernetes Cluster version",
            filename="scripts/day_two_actions/upgrade_k8s_cluster/upgrade_k8s_cluster.py",
            variables=["task_uuid"]
        )
        CalmTask.Exec.escript(
            name="Monitor Karbon Upgrade Task Status",
            filename="scripts/common/monitor_karbon_task_status.py",
        )

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

class KarbonClusterPackage(Package):
    name = "Developer Workstation Package"

    services = [ref(KarbonCluster)]

    @action
    def __install__():
        KarbonCluster.CreateKarbonCluster(name="Create Karbon Cluster")
        #KarbonCluster.CreateProject(name="Create Project")
        #KarbonCluster.InstallKyverno(name="Install Kyverno")
        KarbonCluster.InstallMetalLB(name="Install MetalLB")
        #KarbonCluster.InstallMetricsServer(name="Install Metrics Server")
        KarbonCluster.InstallKubernetesDashboard(name="Install Kubernetes Dashboard")
        KarbonCluster.InstallCertManager(name="Install Certificate Manager")
        KarbonCluster.InstallIngressNginx(name="Install Ingress Nginx")
        KarbonCluster.ConfigureK8sServiceAccount(name="Configure K8s Service Account")
        KarbonCluster.ConfigureDynamicNFS(name="Configure Nutanix Files Dynamic Provisioner")

    @action
    def __uninstall__():
        #KarbonCluster.DeleteProject(name="Delete Project")
        KarbonCluster.DeleteKarbonCluster(name="Delete Karbon Cluster")


class KarbonClusterVM(Substrate):

    name = "Developer Workstation VM"

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

class KarbonClusterDeployment(Deployment):
    """
    KarbonCluster deployment
    """

    packages = [ref(KarbonClusterPackage)]
    substrate = ref(KarbonClusterVM)
    min_replicas = "1"
    max_replicas = "10"


class Default(Profile):
    """
    Default Application profile.
    """

    deployments = [
            KarbonClusterDeployment
            ]
    nutanix_public_key = CalmVariable.Simple.Secret(
        NutanixPublicKey,
        label="Nutanix Public Key",
        is_hidden=True,
        description="SSH public key for the Nutanix user."
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
    domain_name = CalmVariable.Simple(
        os.getenv("DOMAIN_NAME"),
        label="Domain Name",
        is_mandatory=True,
        runtime=True,
        description="Domain name used as suffix for FQDN. Entered similar to 'test.lab' or 'lab.local'."
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
        description="IP address of the Prism Central instance that manages this Calm instance."
    )
    pc_instance_ip = CalmVariable.Simple.string(
        os.getenv("PC_IP_ADDRESS"),
        label="Prism Central IP",
        is_mandatory=True,
        runtime=True,
        description="IP address of the Prism Central instance that manages this Calm instance."
    )
    worker_count = CalmVariable.Simple(
        "1",
        label="Number of Workers",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Number of worker nodes to deploy.",
    )
    storage_container_name = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename="scripts/create_k8s_cluster/get_storage_containers.py",
        ),
        label="Storage Container",
        is_mandatory=True,
        is_hidden=False,
        description="Storage container for Persistent Volume Claims",
    )
    svc_lb_network_range = CalmVariable.Simple(
        os.getenv("K8S_SVC_LB_ADDRESSPOOL"),
        label="Load Balancer Network Range",
        regex="^(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.?){4}-((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.?){4})$",
        validate_regex=True,
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="The network range to be used in the config map for the MetalLB load balancer.\nRange should be on the same network as the Karbon cluster and should be in the form of <Starting IP Address>-<Ending IP Address> , i.e., 10.38.11.80-10.38.11.83",
    )
    network = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename= "scripts/create_k8s_cluster/get_networks.py",
        ),
        label="Network",
        is_mandatory=True,
        is_hidden=False,
        description="Network for the Karbon Kubernetes nodes.",
    )
    node_os_version = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename="scripts/create_k8s_cluster/get_node_os_versions.py",
        ),
        label="OS Version",
        is_mandatory=False,
        is_hidden=False,
        description="OS Version for Karbon Kubernetes nodes.",
    )
    k8s_version = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename="scripts/create_k8s_cluster/get_k8s_versions.py",
        ),
        label="Kubernetes Version",
        is_mandatory=False,
        is_hidden=False,
        description="",
    )
    nutanix_ahv_cluster = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename="scripts/create_k8s_cluster/get_nutanix_ahv_clusters.py",
        ),
        label="Cluster",
        is_mandatory=False,
        is_hidden=False,
        description="AHV cluster to run Karbon Kubernetes Nodes on.",
    )
    namespace = CalmVariable.Simple(
        "default",
        label="Namespace",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="Kubernetes Namespace"
    )
    k8s_cluster_name = CalmVariable.Simple(
        "",
        label="Kubernetes Cluster Name",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        regex="^([a-zA-Z0-9_-]{0,24})$",
        validate_regex=True,
        description="Name of the Kubernetes cluster to be created via Karbon"
    )
    cni_name = CalmVariable.WithOptions(
        ["flannel", "calico"],
        label="CNI",
        default="calico",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Select CNI",
    )
    external_ipv4_addr = CalmVariable.Simple(
        "",
        label="Multi-Master External IP",
        regex="^(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.?){4})$|^(\s{1})$",
        validate_regex=True,
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Only required for clusters of type production. The external ipv4 address will be used to access API server in multi-master config. i.e., 10.38.11.79",
    )
    cluster_type = CalmVariable.WithOptions(
        ["Development", "Production - Multi-Master Active/Passive"],
        label="Cluster Type",
        default="Development",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="Select Cluster Type",
    )
    enable_advanced_karbon_management = CalmVariable.WithOptions(
        ["true", "false"],
        label="Enable Advance Karbon Cluster Management",
        default="false",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="This will configure advanced karbon cluster management",
    )
    autoscaler_enabled = CalmVariable.WithOptions(
        ["true", "false"],
        label="Enable Cluster Node X-Play Autoscaler",
        default="false",
        is_mandatory=True,
        is_hidden=True,
        runtime=True,
        description="This will configure karbon worker nodes with categories to alert XPlay and autoscale",
    )
    autoscaler_max_count = CalmVariable.Simple(
        "5",
        label="Max Number of Nodes to Add via Autoscaler ",
        is_mandatory=True,
        is_hidden=True,
        runtime=True,
        description="Number of worker nodes to deploy.",
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

    @action
    def AddWorkers(name="Add Workers"):
        """
    Scale Out Karbon Worker Nodes
        """
        addtl_worker_count = CalmVariable.Simple(
            "1",
            label="Scale Out Worker Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="Number of Karbon worker nodes to add.",
        )

        KarbonCluster.AddWorkers(name="Add Workers")

    @action
    def RemoveWorkers(name="Remove Workers"):
        """
    Scale In Karbon Worker Nodes
        """
        less_worker_count = CalmVariable.Simple(
            "1",
            label="Scale In Worker Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="Number of Karbon worker nodes to remove.",
        )

        KarbonCluster.RemoveWorkers(name="Remove Workers")

    @action
    def UpgradeKubernetes(name="Upgrade Kubernetes Version"):
        """
    Upgrade Kubernetes Version
        """
        package_version = CalmVariable.WithOptions.FromTask(
            CalmTask.Exec.escript(
                name="",
                filename="scripts/day_two_actions/upgrade_k8s_cluster/get_compatible_versions.py",
            ),
            label="Compatible K8s Versions",
            is_mandatory=False,
            is_hidden=False,
            description="Select Compatible K8s Versions of Karbon Cluster.",
        )

        KarbonCluster.UpgradeKubernetes(name="Upgrade Kubernetes Version")

    # @action
    # def InitAutoscalerStressSim(name="Init AutoScaler Stress Sim"):
    #     """
    # Init AutoScaler Stress Sim
    #     """

    #     KarbonCluster.InitAutoscalerStressSim(name="Init AutoScaler Stress Sim")


    # @action
    # def CleanupAutoscalerStressSim(name="Cleanup AutoScaler Stress Sim"):
    #     """
    # Cleanup AutoScaler Stress Sim
    #     """

    #     KarbonCluster.CleanupAutoscalerStressSim(name="Cleanup CPU Hog AutoScaler Sim")

class KarbonClusterDeploy(Blueprint):
    """
### Karbon Cluster Deployment Blueprint
    """

    profiles = [Default]
    substrates = [
            KarbonClusterVM
            ]
    services = [
            KarbonCluster
            ]
    packages = [
            KarbonClusterPackage
            ]
    credentials = [
            NutanixCred,
            NutanixPasswordCred,
            PrismCentralCred,
            PrismElementCred,
            DockerHubCred,
            ]


def main():
    print(KarbonClusterDeploy.json_dumps(pprint=True))


if __name__ == "__main__":
    main()
