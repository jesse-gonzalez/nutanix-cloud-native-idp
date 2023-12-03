"""
Calm DSL Update Nutanix Objects Buckets
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

ObjectsAccessKey = os.environ['OBJECTS_ACCESS_KEY']
ObjectsSecretKey = os.environ['OBJECTS_SECRET_KEY']
ObjectsCred = basic_cred(
                    ObjectsAccessKey,
                    name="Objects S3 Access Key",
                    type="PASSWORD",
                    password=ObjectsSecretKey,
                    default=False
                )

@runbook
def UpdateObjectsBuckets(credentials=[ObjectsCred]):
    """
    Runbook to manage Nutanix Objects Buckets
    """
    
    objects_buckets_list = Variable.Simple(
        "", 
        label="Objects Bucket List", 
        description="List of Buckets to Create in Nutanix Objects",
        is_mandatory=True,
        runtime=True
    )
    objects_store_dns_fqdn = Variable.Simple(
        "", 
        label="Objects Store Public DNS Endpoint", 
        description="Public DNS FQDN of Nutanix Objects Store",
        is_mandatory=True,
        runtime=True
    )

    Task.Exec.escript(
        name="Update Nutanix Objects Buckets",
        filename="scripts/update_objects_bucket.py"
        )


def main():
    print(runbook_json(UpdateObjectsBuckets))


if __name__ == "__main__":
    main()
