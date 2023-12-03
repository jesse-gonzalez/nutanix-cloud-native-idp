import os
from calm.dsl.builtins import *
from calm.dsl.config import get_context


variable_list = [
   { "value": os.getenv("OBJECTS_BUCKETS_LIST"), "context": "Default", "name": "objects_buckets_list" },
   { "value": os.getenv("OBJECTS_STORE_PUBLIC_IP"), "context": "Default", "name": "objects_store_dns_fqdn" },
]