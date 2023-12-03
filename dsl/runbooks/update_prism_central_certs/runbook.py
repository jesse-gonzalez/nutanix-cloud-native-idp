"""
Generate AWS Route 53 Hosted LetsEncrypt Certs and Update Prism Central
"""

import os
import base64
import json
from pathlib import Path
from calm.dsl.builtins import *
from calm.dsl.config   import get_context
from calm.dsl.runbooks import read_local_file, basic_cred
from calm.dsl.runbooks import runbook, runbook_json
from calm.dsl.runbooks import RunbookTask as Task, RunbookVariable as Variable
from calm.dsl.runbooks import CalmEndpoint as Endpoint, ref

ContextObj = get_context()
init_data = ContextObj.get_init_config()

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

AwsAccessKeyId = os.environ['AWS_ACCESS_KEY_ID']
AwsSecretAccessKey = os.environ['AWS_SECRET_ACCESS_KEY']
AwsAccessCred = basic_cred(
                    AwsAccessKeyId,
                    name="AWS Access Key",
                    type="PASSWORD",
                    password=AwsSecretAccessKey,
                    default=False
                )

@runbook
def UpdatePrismCentralCerts(credentials=[AwsAccessCred,NutanixPasswordCred,PrismCentralCred]):          
  """
  Runbook to Generate AWS Route 53 Hosted LetsEncrypt Certs and Update Prism Central
  """

  pc_instance_ip = CalmVariable.Simple.string(
      os.getenv("NTNX_PC_IP"),
      label="Prism Central IP Address",
      is_mandatory=True,
      runtime=True,
      description="IP address of the Prism Central instance."
  )
  ocp_cluster_name = CalmVariable.Simple(
      "",
      label="Openshift Cluster Name",
      is_mandatory=True,
      is_hidden=False,
      runtime=True,
      description="Name of the Openshift cluster to be created"
  )
  ocp_base_domain = CalmVariable.Simple(
      os.getenv("OCP_BASE_DOMAIN"),
      label="OCP Base Domain Name",
      is_mandatory=True,
      runtime=True,
      description="OCP Base Domain name used as suffix for FQDN. Entered similar to 'ncnlabs.ninja'."
  )

  Task.Exec.ssh(
    name="Create SSL Certs via Acme Client",
    filename="scripts/create_acme_ssl_certs.sh",
    target=ref(Endpoint.use_existing("bastion_host_svm"))
  )

  Task.Exec.ssh(
    name="Update Prism Central Certs",
    filename="scripts/update_prism_central_certs.sh",
    target=ref(Endpoint.use_existing("bastion_host_svm"))
  )

def main():
    print(runbook_json(UpdatePrismCentralCerts))


if __name__ == "__main__":
    main()
