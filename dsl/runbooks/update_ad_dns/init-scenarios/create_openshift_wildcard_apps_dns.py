import os

WILDCARD_OCP_APPS_INGRESS_STUB = "*." + os.getenv("OCP_APPS_INGRESS_DNS_SHORT")

variable_list = [
   { "value": os.getenv("DOMAIN_NAME"), "context": "Default", "name": "domain_name" },
   { "value": os.getenv("DNS"), "context": "Default", "name": "dns_server" },
   { "value": WILDCARD_OCP_APPS_INGRESS_STUB, "context": "Default", "name": "dns_name" },
   { "value": os.getenv("OCP_APPS_INGRESS_VIP"), "context": "Default", "name": "dns_ip_address" },
   { "value": "Create", "context": "Default", "name": "update_type" }
]
