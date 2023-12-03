"""
Calm DSL Update AWS Route 53 DNS Runbook
"""

import os
from pathlib import Path
from calm.dsl.builtins import *
from calm.dsl.config   import get_context
from calm.dsl.runbooks import runbook, runbook_json
from calm.dsl.runbooks import RunbookTask as Task, RunbookVariable as Variable
from calm.dsl.runbooks import CalmEndpoint as Endpoint, ref

ContextObj = get_context()
init_data = ContextObj.get_init_config()

DNSServer = os.getenv("DNS")
DomainName = os.getenv("AWS_ROUTE53_DOMAIN")

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
def UpdateAwsRoute53(credentials=[AwsAccessCred]):
    """
    Runbook to Update AWS Route 53 DNS Runbook
    """
    dns_name = Variable.Simple(
        "",
        label="DNS Name", 
        description="Name of DNS A HOST Record",
        is_mandatory=True,
        runtime=True
    )
    domain_name = Variable.Simple(
        DomainName,
        label="Domain Name",
        description="Name of AWS Route 53 Hosted Zone",
        is_hidden=True,
        runtime=False
    ) 
    dns_ip_address = Variable.Simple(
        "",
        label="DNS IP Address",
        description="IP Address for the DNS name to be managed",
        is_mandatory=True,
        runtime=True
    ) 
    update_type = Variable.WithOptions.Predefined.string(
        [
            "Create",
            "Delete"
        ],
        default="Create",
        label="Update Type",
        description="Select update to be performed",
        is_mandatory=True,
        runtime=True
    ) 

    with Task.Decision.escript(
        name="Create or Delete Decision",
        filename="scripts/create_delete_decision.py",
    ) as d:
        if d.exit_code == 0:
            Task.Exec.escript(
                name="Create IP Record",
                filename="scripts/create_route53_dns.py",
            )
        if d.exit_code == 1:
            Task.Exec.escript(
                name="Delete IP Record",
                filename="scripts/delete_route53_dns.py",
            )

def main():
    print(runbook_json(UpdateAwsRoute53))


if __name__ == "__main__":
    main()
