import os
from calm.dsl.builtins import *
from calm.dsl.config import get_context

variable_list = [
   { "value": os.getenv("NTNX_PC_IP"), "context": "Default", "name": "pc_instance_ip" },
   { "value": os.getenv("OCP_CLUSTER_NAME"), "context": "Default", "name": "ocp_cluster_name" },
   { "value": os.getenv("OCP_BASE_DOMAIN"), "context": "Default", "name": "ocp_base_domain" },
]