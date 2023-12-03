helm_chart_namespace = "github-runners"
helm_chart_instance_name = "github-runners"

import os

GITHUB_REPO_URL="https://github.com/jesse-gonzalez/cloud-native-calm.git"

variable_list = [
    { "value": { "value": os.getenv("DOMAIN_NAME") }, "context": "Default", "name": "domain_name" },
    { "value": { "value": os.getenv("PC_PORT") }, "context": "Default", "name": "pc_instance_port" },
    { "value": { "value": os.getenv("PC_IP_ADDRESS") }, "context": "Default", "name": "pc_instance_ip" },
    { "value": { "value": helm_chart_namespace }, "context": "Default", "name": "namespace" },
    { "value": { "value": os.getenv("KARBON_CLUSTER") }, "context": "Default", "name": "k8s_cluster_name"},
    { "value": { "value": helm_chart_instance_name }, "context": "Default", "name": "instance_name"},
    { "value": { "value": os.getenv("WILDCARD_INGRESS_DNS_FQDN") }, "context": "Default", "name": "wildcard_ingress_dns_fqdn"},
    { "value": { "value": os.getenv("GITHUB_REPO_URL") }, "context": "Default", "name": "github_repo_url"},
    
]

