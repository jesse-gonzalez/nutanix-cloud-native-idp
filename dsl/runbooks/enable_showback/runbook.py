"""
Calm DSL Enable Calm Showback Runbook
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

policy_vm_ip = os.getenv("CALM_POLICY_ENGINE_VM_IP")

@runbook
def EnableCalmShowback():
    """
    Runbook to enable Calm showback
    """

    Task.HTTP.post(
        name="Enable Calm Showback",
        target=ref(Endpoint.use_existing("prism_central_endpoint")),
        relative_url='/api/nutanix/v3/app_showback/enable',
        body="",
        content_type="application/json",
        status_mapping={200: True},
    )


def main():
    print(runbook_json(EnableCalmShowback))


if __name__ == "__main__":
    main()