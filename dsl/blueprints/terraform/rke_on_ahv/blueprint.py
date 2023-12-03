# THIS FILE IS AUTOMATICALLY GENERATED.
"""
Calm DSL for RKE_Admin_Workstation blueprint

"""

import base64
import os
import json
from calm.dsl.builtins import *
from calm.dsl.config import get_context

ContextObj = get_context()
init_data = ContextObj.get_init_config()

# Get the values from environment vars

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
PrismElementCred = basic_cred(
        PrismElementUser,
        name="Prism Element User",
        type="PASSWORD",
        password=PrismElementPassword,
        default=False
    )

EncrypedPrismCentralCreds = base64.b64encode(bytes(PrismCentralPassword, 'utf-8'))

EncrypedPrismElementCreds = base64.b64encode(bytes(PrismElementPassword, 'utf-8'))

# OS Image details for VM
# Centos74_Image = vm_disk_package(
#         name="centos7_generic",
#         config_file="image_configs/centos74_disk.yaml"
#     )

BastionHostEndpoint = os.getenv("BASTION_WS_ENDPOINT")

class Rke_WorkstationService(Service):
    """Workstation Service"""

    @action
    def DeployRKECluster(name="Deploy RKE"):
        CalmTask.Exec.ssh(
            name="Clone RKE Terraform Repo",
            filename="scripts/terraform_deploy/clone_repo.sh",
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Initialize Terraform",
            filename="scripts/terraform_deploy/initialize_terraform.sh",
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Apply Terraform",
            filename="scripts/terraform_deploy/terraform_apply.sh",
            cred=NutanixCred
        )
        CalmTask.Exec.ssh(
            name="Validate RKE",
            filename="scripts/terraform_deploy/validate_rke_cluster.sh",
            cred=NutanixCred
        )


    @action
    def Rke_Scale_In_Cluster():
        ScaleIn = CalmVariable.Simple.int(
            "1",
            label="",
            regex="^[\d]*$",
            validate_regex=False,
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="",
        )
        CalmTask.Exec.ssh(
            name="Scale_In_Cluster",
            filename="scripts/day_two_actions/terraform_scale_in.sh",
            cred=NutanixCred
        )

    @action
    def Rke_Scale_Out_Cluster():
        ScaleOut = CalmVariable.Simple.int(
            "1",
            label="",
            regex="^[\d]*$",
            validate_regex=False,
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="",
        )
        CalmTask.Exec.ssh(
            name="Scale_Out_Cluster",
            filename="scripts/day_two_actions/terraform_scale_out.sh",
            cred=NutanixCred
        )


    # @action
    # def Rke_Upgrade_Cluster():

    #     CalmTask.Exec.ssh(
    #         filename="scripts/anthos_upgrade_cluster.sh",
    #         name="Upgrade_Cluster"
    #     )

    @action
    def Rke_Destroy_Cluster():

        CalmTask.Exec.ssh(
            name="Rke_Destroy_Cluster",
            filename="scripts/day_two_actions/terraform_destroy.sh",
            cred=NutanixCred
        )

    @action
    def __delete__():
        """System action for deleting an application. Deletes created VMs as well"""

        Rke_WorkstationService.Rke_Destroy_Cluster(name="Rke_Destroy_Cluster")


class Rke_WorkstationPackage(Package):
    """Workstation Package"""

    # Services created by installing this Package
    services = [ref(Rke_WorkstationService)]

    @action
    def __install__():
        Rke_WorkstationService.DeployRKECluster(name="Deploy RKE Cluster")


class Rke_WorkstationSubstrate(Substrate):
    name = "RKE Admin Workstation VM"

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

    # @action
    # def __pre_create__():
    #     CalmTask.SetVariable.escript(
    #         name="Set Lowercase App Name",
    #         filename="../_common/centos/scripts/set_lower_case_app_name.py",
    #         variables=["app_name"],
    #     )


class Rke_WorkstationDeployment(Deployment):
    """Workstation Deployment"""

    packages = [ref(Rke_WorkstationPackage)]
    substrate = ref(Rke_WorkstationSubstrate)
    min_replicas = "1"
    max_replicas = "10"


class Rke_WorkstationProfile(Profile):

    # Deployments under this profile
    deployments = [Rke_WorkstationDeployment]

    nutanix_public_key = CalmVariable.Simple.Secret(
        NutanixPublicKey,
        label="Nutanix Public Key",
        is_hidden=True,
        description="SSH public key for the Nutanix user."
    )
    domain_name = CalmVariable.Simple(
        os.getenv("DOMAIN_NAME"),
        label="Domain Name",
        is_mandatory=True,
        runtime=True,
        description="Domain name used as suffix for FQDN. Entered similar to 'test.lab' or 'lab.local'."
    )
    pc_instance_port = CalmVariable.Simple.string(
        "9440",
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

    rke_cluster_name = CalmVariable.Simple.string(
        os.getenv("RKE_CLUSTER_NAME"),
        name="RKE Cluster Name",
        label="Rke cluster name",
        is_mandatory=True,
        runtime=True
    )

    pe_cluster_vip = CalmVariable.Simple.string(
        os.getenv("PE_CLUSTER_VIP"),
        name="Nutanix Prism Element Cluster VIP",
        label="Prism Element VIP",
        regex="^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
        validate_regex=True,
        description="This is needed for the CSI driver to create persistent volumes via the API",
        is_mandatory=True,
        runtime=True
    )

    pe_port = CalmVariable.Simple.string(
        os.getenv("PE_PORT"),
        name="Nutanix Prism Element Port",
        label="Prism Element port",
        regex="^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$",
        validate_regex=True,
        is_mandatory=True,
        runtime=True
    )

    pe_dataservices_vip = CalmVariable.Simple.string(
        os.getenv("PE_DATASERVICES_VIP"),
        name="Nutanix Prism Element Data Service VIP",
        label="Data service IP address",
        regex="^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
        validate_regex=True,
        description="""Data service is required to allow iSCSI connectivity between the
            Kubernetes pods and the volumes created by CSI""",
        is_mandatory=True,
        runtime=True
    )

    pe_storage_container = CalmVariable.Simple.string(
        os.getenv("PE_STORAGE_CONTAINER"),
        name="Nutanix Prism Element Storage Container",
        label="Storage Container in Prism Element",
        description="""This is the Nutanix Storage Container where the requested Persistent Volume Claims will
            get their volumes created. You can enable things like compression and deduplication in a Storage Container.
            The recommendation is to create at least one storage container in Prism Element well identified for Kubernetes usage.
            This will facilitate the search of persistent volumes when the environment scales""",
        is_mandatory=True,
        runtime=True
    )

    @action
    def ScaleOut():
        """This action will scale out worker nodes by given scale out count"""

        ScaleOut = CalmVariable.Simple.int(
            "1",
            label="",
            regex="^[\d]*$",
            validate_regex=False,
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="",
        )
        Rke_WorkstationService.Rke_Scale_Out_Cluster(name="Rke_Scale_Out_Cluster")

    @action
    def ScaleIn():
        """This action will scale in workder nodes by given scale in count"""

        ScaleIn = CalmVariable.Simple.int(
            "1",
            label="",
            regex="^[\d]*$",
            validate_regex=False,
            is_mandatory=True,
            is_hidden=False,
            runtime=True,
            description="",
        )
        Rke_WorkstationService.Rke_Scale_In_Cluster(name="Rke_Scale_In_Cluster")


class Rke_Workstation(Blueprint):
    """ Blueprint for Rke_Workstation app using AHV VM"""

    credentials = [
            NutanixCred,
            NutanixPasswordCred,
            PrismCentralCred,
            PrismElementCred,
    ]
    services = [Rke_WorkstationService]
    packages = [Rke_WorkstationPackage]
    substrates = [Rke_WorkstationSubstrate]
    profiles = [Rke_WorkstationProfile]
