import os

variable_list = [
   { "value": os.getenv("AWS_ROUTE53_DOMAIN"), "context": "Default", "name": "domain_name" },
   { "value": os.getenv("DNS"), "context": "Default", "name": "dns_server" },
   { "value": os.getenv("OCP_NTNX_PC_DNS_FQDN"), "context": "Default", "name": "dns_name" },
   { "value": os.getenv("NTNX_PC_IP"), "context": "Default", "name": "dns_ip_address" },
   { "value": "Create", "context": "Default", "name": "update_type" }
]