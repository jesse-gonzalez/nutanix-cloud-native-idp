"""
Calm DSL Enable Policy Engine
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
def EnablePolicyEngine():
    """
    Runbook to Enable Policy Engine
    """

    Task.HTTP.get(
        name="Get Policy Engine UUID",
        target=ref(Endpoint.use_existing("prism_central_endpoint")),
        relative_url='/api/calm/v3.0/features/policy',
        content_type="application/json",
        status_mapping={200: True},
        response_paths={"policy_engine_uuid": "$.metadata.uuid"},
    )

    Task.HTTP.put(
        name="Enable Policy Engine",
        target=ref(Endpoint.use_existing("prism_central_endpoint")),
        relative_url='/api/calm/v3.0/features/policy',
        body=json.dumps({
                            "spec": {
                                "feature_status": {
                                "is_enabled": True,
                                "config": {
                                    "data": {
                                    "ip_list": [
                                        policy_vm_ip
                                    ]
                                    }
                                },
                                "is_ignored": False
                                }
                            },
                            "api_version": "3.1",
                            "metadata": {
                                "kind": "calm_feature",
                                "spec_version": 0,
                                "name": "",
                                "uuid": "@@{policy_engine_uuid}@@"
                            }
                        }),
        content_type="application/json",
        status_mapping={200: True},
    )


def main():
    print(runbook_json(EnablePolicyEngine))


if __name__ == "__main__":
    main()

