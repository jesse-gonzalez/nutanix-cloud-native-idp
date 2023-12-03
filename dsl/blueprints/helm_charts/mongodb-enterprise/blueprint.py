
"""
Blueprint to Deploy Helm Chart onto Target Karbon Cluster
"""

## Update at minimum these vars
helm_chart_name = "MongodbEnterprise"
helm_chart_namespace = "mongodb-enterprise"
helm_chart_instance_name = "mongodb-enterprise"

import base64
import json
import os
from calm.dsl.builtins import *
from calm.dsl.config import get_context

ContextObj = get_context()
init_data = ContextObj.get_init_config()

PrismCentralUser = os.environ['PRISM_CENTRAL_USER']
PrismCentralPassword = os.environ['PRISM_CENTRAL_PASS']
PrismCentralCred = basic_cred(
                    PrismCentralUser,
                    name="Prism Central User",
                    type="PASSWORD",
                    password=PrismCentralPassword,
                    default=False
                )

EncrypedPrismCreds = base64.b64encode(bytes(PrismCentralPassword, 'utf-8'))

NutanixKeyUser = os.environ['NUTANIX_KEY_USER']
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

MongoDBUser = os.environ['MONGODB_USER']
MongoDBPassword = os.environ['MONGODB_PASS']
MongoDBCred = basic_cred(
                    MongoDBUser,
                    name="MongoDB User",
                    type="PASSWORD",
                    password=MongoDBPassword,
                    default=False
                )

BastionHostEndpoint = os.getenv("BASTION_WS_ENDPOINT")

class HelmService(Service):

    name = "Helm_"+helm_chart_name

    nipio_ingress_domain = CalmVariable.Simple.string("",)
    opsmanager_base_url = CalmVariable.Simple.string("",)
    opsmanager_org_id = CalmVariable.Simple.string("",)
    opsmanager_api_user = CalmVariable.Simple.string("",)
    opsmanager_api_key = CalmVariable.Simple.string("",)
    opsmanager_version = CalmVariable.Simple.string("",)
    opsmanager_appdb_version = CalmVariable.Simple.string("",)
    opsmanager_replicaset_count = CalmVariable.Simple.string("",)
    opsmanager_appdb_replicaset_count = CalmVariable.Simple.string("",)

    mongodb_appdb_version = CalmVariable.Simple.string("",)
    mongodb_appdb_container_image = CalmVariable.Simple.string("",)
    mongodb_appdb_cpu_limits = CalmVariable.Simple.string("",)
    mongodb_appdb_mem_limits = CalmVariable.Simple.string("",)
    mongodb_appdb_data_size = CalmVariable.Simple.string("",)
    mongodb_appdb_logs_size = CalmVariable.Simple.string("",)
    mongodb_appdb_journal_size = CalmVariable.Simple.string("",)
    mongodb_appdb_replicaset_count = CalmVariable.Simple.string("",)
    mongodb_appdb_shard_count = CalmVariable.Simple.string("",)
    mongodb_appdb_mongods_per_shard_count = CalmVariable.Simple.string("",)
    mongodb_appdb_monogos_count = CalmVariable.Simple.string("",)
    mongodb_appdb_shard_count = CalmVariable.Simple.string("",)
    mongodb_appdb_configserver_count = CalmVariable.Simple.string("",)
    mongodb_appdb_storage_class = CalmVariable.Simple.string("",)
    mongodb_standalone_instance_name = CalmVariable.Simple.string("",)
    mongodb_sharded_instance_name = CalmVariable.Simple.string("",)
    mongodb_replicaset_instance_name = CalmVariable.Simple.string("",)

    @action
    def InstallHelmChart(name="Install "+helm_chart_name):
        CalmTask.Exec.ssh(
            name="Get Kubeconfig",
            filename="../../../_common/karbon/scripts/get_kubeconfig.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )
        CalmTask.Exec.ssh(
            name="Validate PreReqs",
            filename="scripts/deploy_helm_chart/validate_prereq.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )
        CalmTask.Exec.ssh(
            name="Install "+helm_chart_name+" Helm Chart",
            filename="scripts/deploy_helm_chart/install_helm_chart.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )

    @action
    def UninstallHelmChart(name="Uninstall "+helm_chart_name):

        CalmTask.Exec.ssh(
            name="Get Kubeconfig",
            filename="../../../_common/karbon/scripts/get_kubeconfig.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )
        CalmTask.Exec.ssh(
            name="Uninstall "+helm_chart_name+" Helm Chart",
            filename="scripts/deploy_helm_chart/uninstall_helm_chart.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )

    @action
    def ConfigureOpsManager(name="Configure OpsManager Instance"):
        CalmTask.Exec.ssh(
            name="Configuring MongoDB Instance",
            filename="scripts/deploy_helm_chart/configure_opsmanager_instance.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )
        CalmTask.SetVariable.ssh(
            name="Set Service Variables",
            filename="scripts/deploy_helm_chart/set_service_variables.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred),
            variables=["nipio_ingress_domain"]
        )

    @action
    def ConfigureMongoDBStandalone(name="Configure MongoDB Standalone Instance"):
        CalmTask.Exec.ssh(
            name="Get Kubeconfig",
            filename="../../../_common/karbon/scripts/get_kubeconfig.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )
        CalmTask.Exec.ssh(
            name="Configure MongoDB Clusters",
            filename="scripts/day_two_actions/configure_mongodb_standalone.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )

    @action
    def ConfigureMongoDBReplicaSet(name="Configure MongoDB ReplicaSet Cluster"):
        CalmTask.Exec.ssh(
            name="Get Kubeconfig",
            filename="../../../_common/karbon/scripts/get_kubeconfig.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )
        CalmTask.Exec.ssh(
            name="Configure MongoDB Clusters",
            filename="scripts/day_two_actions/configure_mongodb_replicaset.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )

    @action
    def ConfigureMongoDBSharded(name="Configure MongoDB Sharded Cluster"):
        CalmTask.Exec.ssh(
            name="Get Kubeconfig",
            filename="../../../_common/karbon/scripts/get_kubeconfig.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )
        CalmTask.Exec.ssh(
            name="Configure MongoDB Clusters",
            filename="scripts/day_two_actions/configure_mongodb_sharded.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )


class BastionHostWorkstation(Substrate):

    os_type = "Linux"
    provider_type = "EXISTING_VM"
    provider_spec = read_provider_spec(os.path.join("image_configs", "bastionctl_workstation_provider_spec.yaml"))

    provider_spec.spec["address"] = BastionHostEndpoint

    readiness_probe = readiness_probe(
        connection_type="SSH",
        disabled=False,
        retries="5",
        connection_port=22,
        address=BastionHostEndpoint,
        delay_secs="60",
        credential=ref(NutanixCred),
    )


class HelmPackage(Package):

    services = [ref(HelmService)]

    @action
    def __install__():
        HelmService.InstallHelmChart(name="Install "+helm_chart_name)
        #HelmService.ConfigureOpsManager(name="Configuring OpsManager")

    @action
    def __uninstall__():
        HelmService.UninstallHelmChart(name="Uninstall "+helm_chart_name)


class HelmDeployment(Deployment):

    name = "Helm Deployment"
    min_replicas = "1"
    max_replicas = "1"
    default_replicas = "1"

    packages = [ref(HelmPackage)]
    substrate = ref(BastionHostWorkstation)


class Default(Profile):

    deployments = [HelmDeployment]

    pc_instance_ip = CalmVariable.Simple(
        os.getenv("PC_IP_ADDRESS"),
        label="",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    pc_instance_port = CalmVariable.Simple(
        "9440",
        label="",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    instance_name = CalmVariable.Simple(
        helm_chart_instance_name,
        label=helm_chart_name+" Instance Name",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Helm Instance Release Name",
    )

    wildcard_ingress_dns_fqdn = CalmVariable.Simple(
        os.getenv("WILDCARD_INGRESS_DNS_FQDN"),
        label="Wildcard Ingress Domain",
        is_mandatory=True,
        is_hidden=True,
        runtime=True,
        description="Wildcard Ingress Domain for Applications, must be unique per Karbon cluster - i.e., dev.karbon-infra.drm-poc.local",
    )

    k8s_cluster_name = CalmVariable.WithOptions.FromTask(
        CalmTask.Exec.escript(
            name="",
            filename="../../../_common/karbon/scripts/get_karbon_cluster_list.py",
        ),
        label="Kubernetes Cluster Name",
        is_mandatory=True,
        is_hidden=False,
        description="Target Karbon Cluster Name",
    )

    namespace = CalmVariable.Simple(
        helm_chart_namespace,
        label=helm_chart_name+" Namespace",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="Kubernetes Namespace to deploy helm chart",
    )

    enc_pc_creds = CalmVariable.Simple(
        EncrypedPrismCreds.decode("utf-8"),
        is_mandatory=True,
        is_hidden=True,
        runtime=False,
    )
    @action
    def ConfigureOpsManager(name="Configure OpsManager Instance"):
        """
    Configure MongoDB OpsManager Instance
        """
        opsmanager_version = CalmVariable.Simple(
            os.getenv("OPSMANAGER_VERSION"),
            label="OpsManager Version",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="OpsManager Version",
        )

        opsmanager_appdb_version = CalmVariable.Simple(
            os.getenv("OPSMANAGER_APPDB_VERSION"),
            label="OpsManager MongoDB AppDB Version",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="OpsManager MongoDB AppDB Version",
        )

        opsmanager_replicaset_count = CalmVariable.Simple(
            os.getenv("OPSMANAGER_REPLICASET_COUNT"),
            label="OpsManager Replicaset Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="OpsManager Replicaset Count",
        )

        opsmanager_appdb_replicaset_count = CalmVariable.Simple(
            os.getenv("OPSMANAGER_APPDB_REPLICASET_COUNT"),
            label="OpsManager Backend AppDB Replicaset Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="OpsManager Backend AppDB Replicaset Count",
        )

        HelmService.ConfigureOpsManager(name="Configure OpsManager Instance")

    @action
    def ConfigureMongoDBStandalone(name="Configure MongoDB Standalone Instance"):
        """
    Configure Standalone Mongodb Instance
        """
        opsmanager_base_url = CalmVariable.Simple(
            "",
            label="OpsManager External URL Endpoint [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager External URL Endpoint - only if registeristing from external K8s clusters. i.e., http://opsmanager-ext.ntnxlab.local",
        )
        opsmanager_org_id = CalmVariable.Simple(
            "",
            label="OpsManager Organization ID [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager Organization ID. i.e., 62c7a4dbbdff127f78561be3",
        )
        opsmanager_api_user = CalmVariable.Simple(
            "",
            label="OpsManager API Key User [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager API Key User. i.e., jgejkwud",
        )
        opsmanager_api_key = CalmVariable.Simple(
            "",
            label="OpsManager API Key [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager API Key. i.e., 827c16bb-5f6e-4ed8-a234-95066d7a6684",
        )
        mongodb_appdb_version = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_VERSION"),
            label="MongoDB AppDB Version",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Version",
        )
        mongodb_appdb_container_image = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_CONTAINER_IMAGE"),
            label="MongoDB AppDB Container Image Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Container Image Name",
        )
        mongodb_appdb_cpu_limits = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_CPU_LIMITS"),
            label="MongoDB AppDB CPU Limits",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB CPU Limits",
        )
        mongodb_appdb_mem_limits = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_MEM_LIMITS"),
            label="MongoDB AppDB Memory Limits",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Memory Limits",
        )
        mongodb_appdb_data_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_DATA_SIZE"),
            label="MongoDB AppDB Data Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Data Mount Size",
        )
        mongodb_appdb_logs_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_LOGS_SIZE"),
            label="MongoDB AppDB Logs Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Logs Mount Size",
        )
        mongodb_appdb_journal_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_JOURNAL_SIZE"),
            label="MongoDB AppDB Journal Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Journal Mount Size",
        )
        mongodb_appdb_storage_class = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_STORAGE_CLASS"),
            label="Storage Class Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="Storage Class Name",
        )
        mongodb_standalone_instance_name = CalmVariable.Simple(
            os.getenv("MONGODB_STANDALONE_INSTANCE_NAME"),
            label="MongoDB Standalone Instance Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB Standalone Instance Name, to be used for K8s Namespace and OpsManagerProject",
        )

        HelmService.ConfigureMongoDBStandalone(name="Configure MongoDB Standalone Instance")

    @action
    def ConfigureMongoDBReplicaSet(name="Configure MongoDB ReplicaSet Cluster"):
        """
    Configure MongoDB ReplicaSet Cluster
        """

        opsmanager_base_url = CalmVariable.Simple(
            "",
            label="OpsManager External URL Endpoint [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager External URL Endpoint - only if registeristing from external K8s clusters. i.e., http://opsmanager-ext.ntnxlab.local",
        )
        opsmanager_org_id = CalmVariable.Simple(
            "",
            label="OpsManager Organization ID [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager Organization ID. i.e., 62c7a4dbbdff127f78561be3",
        )
        opsmanager_api_user = CalmVariable.Simple(
            "",
            label="OpsManager API Key User [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager API Key User. i.e., jgejkwud",
        )
        opsmanager_api_key = CalmVariable.Simple(
            "",
            label="OpsManager API Key [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager API Key. i.e., 827c16bb-5f6e-4ed8-a234-95066d7a6684",
        )
        mongodb_appdb_replicaset_count = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_REPLICASET_COUNT"),
            label="MongoDB AppDB ReplicaSet Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB ReplicaSet Count",
        )
        mongodb_appdb_version = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_VERSION"),
            label="MongoDB AppDB Version",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Version",
        )
        mongodb_appdb_container_image = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_CONTAINER_IMAGE"),
            label="MongoDB AppDB Container Image Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Container Image Name",
        )
        mongodb_appdb_cpu_limits = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_CPU_LIMITS"),
            label="MongoDB AppDB CPU Limits",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB CPU Limits",
        )
        mongodb_appdb_mem_limits = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_MEM_LIMITS"),
            label="MongoDB AppDB Memory Limits",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Memory Limits",
        )
        mongodb_appdb_data_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_DATA_SIZE"),
            label="MongoDB AppDB Data Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Data Mount Size",
        )
        mongodb_appdb_logs_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_LOGS_SIZE"),
            label="MongoDB AppDB Logs Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Logs Mount Size",
        )
        mongodb_appdb_journal_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_JOURNAL_SIZE"),
            label="MongoDB AppDB Journal Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Journal Mount Size",
        )
        mongodb_appdb_storage_class = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_STORAGE_CLASS"),
            label="Storage Class Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="Storage Class Name",
        )
        mongodb_replicaset_instance_name = CalmVariable.Simple(
            os.getenv("MONGODB_REPLICASET_INSTANCE_NAME"),
            label="MongoDB ReplicaSet Cluster Instance Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB ReplicaSet Cluster Instance Name, to be used for K8s Namespace and OpsManager Project",
        )

        HelmService.ConfigureMongoDBReplicaSet(name="Configure MongoDB ReplicaSet Cluster")

    @action
    def ConfigureMongoDBSharded(name="Configure MongoDB Sharded Cluster"):
        """
    Configure MongoDB Sharded Cluster
        """

        opsmanager_base_url = CalmVariable.Simple(
            "",
            label="OpsManager External URL Endpoint [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager External URL Endpoint - only if registeristing from external K8s clusters. i.e., http://opsmanager-ext.ntnxlab.local",
        )
        opsmanager_org_id = CalmVariable.Simple(
            "",
            label="OpsManager Organization ID [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager Organization ID. i.e., 62c7a4dbbdff127f78561be3",
        )
        opsmanager_api_user = CalmVariable.Simple(
            "",
            label="OpsManager API Key User [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager API Key User. i.e., jgejkwud",
        )
        opsmanager_api_key = CalmVariable.Simple(
            "",
            label="OpsManager API Key [Optional]",
            is_mandatory=False,
            is_hidden=False,
            runtime=True,
            description="OpsManager API Key. i.e., 827c16bb-5f6e-4ed8-a234-95066d7a6684",
        )
        mongodb_appdb_shard_count = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_SHARD_COUNT"),
            label="MongoDB AppDB Shard Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Shard Count",
        )
        mongodb_appdb_mongods_per_shard_count = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_MONGODS_PER_SHARD_COUNT"),
            label="MongoDB AppDB Mongods per Shard Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Mongods per Shard Count",
        )
        mongodb_appdb_monogos_count = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_MONGOS_COUNT"),
            label="MongoDB AppDB Mongos Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Mongos Count",
        )
        mongodb_appdb_configserver_count = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_CONFIGSERVER_COUNT"),
            label="MongoDB AppDB ConfigServer Count",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB ConfigServer Count",
        )
        mongodb_appdb_version = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_VERSION"),
            label="MongoDB AppDB Version",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Version",
        )
        mongodb_appdb_container_image = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_CONTAINER_IMAGE"),
            label="MongoDB AppDB Container Image Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Container Image Name",
        )
        mongodb_appdb_cpu_limits = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_CPU_LIMITS"),
            label="MongoDB AppDB CPU Limits",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB CPU Limits",
        )
        mongodb_appdb_mem_limits = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_MEM_LIMITS"),
            label="MongoDB AppDB Memory Limits",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Memory Limits",
        )
        mongodb_appdb_data_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_DATA_SIZE"),
            label="MongoDB AppDB Data Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Data Mount Size",
        )
        mongodb_appdb_logs_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_LOGS_SIZE"),
            label="MongoDB AppDB Logs Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Logs Mount Size",
        )
        mongodb_appdb_journal_size = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_JOURNAL_SIZE"),
            label="MongoDB AppDB Journal Mount Size",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB AppDB Journal Mount Size",
        )
        mongodb_appdb_storage_class = CalmVariable.Simple(
            os.getenv("MONGODB_APPDB_STORAGE_CLASS"),
            label="Storage Class Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="Storage Class Name",
        )
        mongodb_sharded_instance_name = CalmVariable.Simple(
            os.getenv("MONGODB_SHARDED_INSTANCE_NAME"),
            label="MongoDB Sharded Cluster Instance Name",
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="MongoDB Shard Cluster Instance Name, to be used for K8s Namespace and OpsManager Project",
        )

        HelmService.ConfigureMongoDBSharded(name="Configure MongoDB Sharded Cluster")


class HelmBlueprint(Blueprint):

    services = [HelmService]
    packages = [HelmPackage]
    substrates = [BastionHostWorkstation]
    profiles = [Default]
    credentials = [PrismCentralCred, NutanixCred, MongoDBCred]
