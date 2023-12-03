"""
Calm DSL Update AppType Categories
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

PrismCentralUser = os.environ['PRISM_CENTRAL_USER']
PrismCentralPassword = os.environ['PRISM_CENTRAL_PASS']
PrismCentralCred = basic_cred(
                    PrismCentralUser,
                    name="Prism Central User",
                    type="PASSWORD",
                    password=PrismCentralPassword,
                    default=False
                )

@runbook
def UpdateAppTypeCategories(credentials=[PrismCentralCred]):
    """
    Runbook to manage AppType Categories
    """
    
    categories_list = Variable.Simple(
        "", 
        label="AppType Category List", 
        description="List of Categories to Add to AppType",
        is_mandatory=True,
        runtime=True
    )

    Task.Exec.escript(
        name="Update AppType Categories",
        filename="scripts/update_app_type_categories.py"
        )


def main():
    print(runbook_json(UpdateAppTypeCategories))


if __name__ == "__main__":
    main()
