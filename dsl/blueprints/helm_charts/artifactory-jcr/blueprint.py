
"""
Blueprint to Deploy Helm Chart onto Target Karbon Cluster
"""

helm_chart_name = "JFrogContainerRegistry"
helm_chart_namespace = "jfrog-container-registry"
helm_chart_instance_name = "artifactory-jcr"

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

ArtifactoryPassword = os.environ['ARTIFACTORY_PASS']
ArtifactoryCred = basic_cred(
                    "admin",
                    name="Artifactory Credential",
                    type="PASSWORD",
                    password=ArtifactoryPassword,
                    default=False
                )

BastionHostEndpoint = os.getenv("BASTION_WS_ENDPOINT")
class HelmService(Service):

    name = "Helm_"+helm_chart_name

    nipio_ingress_domain = CalmVariable.Simple.string("",)

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
        CalmTask.SetVariable.ssh(
            name="Set Service Variables",
            filename="scripts/deploy_helm_chart/set_service_variables.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred),
            variables=["nipio_ingress_domain"]
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
    def ConfigureService(name="Configuring "+helm_chart_name):
        CalmTask.Exec.ssh(
            name="Configuring Docker and Helm Repositories",
            filename="scripts/configure_artifactory/configure_artifactory_repos.sh",
            target=ref(HelmService),
            cred=ref(NutanixCred)
        )

    @action
    def AddKarbonRegistry(name="Add Private Docker Registry to Karbon"):
        CalmTask.Exec.ssh(
            name="Create Docker Registry Kubernetes Credential",
            filename="scripts/configure_k8s_cluster/create_k8s_credential.sh",
            target=ref(HelmService),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Add Private Docker Registry",
            filename="scripts/configure_k8s_cluster/configure_karbon_cluster.sh",
            target=ref(HelmService),
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Validate Docker and Helm Repos",
            filename="scripts/configure_k8s_cluster/validate_registry_configs.sh",
            target=ref(HelmService),
            cred=NutanixCred
        )

    @action
    def DeleteKarbonRegistry(name="Delete Private Docker Registry from Karbon"):
        CalmTask.Exec.ssh(
            name="Delete Private Docker Registry",
            filename="scripts/configure_k8s_cluster/delete_docker_registry.sh",
            target=ref(HelmService),
            cred=NutanixCred
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
        HelmService.ConfigureService(name="Configure "+helm_chart_name)
        HelmService.AddKarbonRegistry(name="Add Docker Registry to Karbon")

    @action
    def __uninstall__():
        HelmService.DeleteKarbonRegistry(name="Delete Docker Registry from Karbon")
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
        is_hidden=False,
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

class HelmBlueprint(Blueprint):

    services = [HelmService]
    packages = [HelmPackage]
    substrates = [BastionHostWorkstation]
    profiles = [Default]
    credentials = [PrismCentralCred, NutanixCred, ArtifactoryCred]
