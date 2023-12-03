import os

variable_list = [
    { "value": { "value": os.getenv("DOMAIN_NAME") }, "context": "Default", "name": "domain_name" },
    { "value": { "value": os.getenv("PC_PORT") }, "context": "Default", "name": "pc_instance_port" },
    { "value": { "value": os.getenv("PC_IP_ADDRESS") }, "context": "Default", "name": "pc_instance_ip" },
    { "value": { "value": os.getenv("RKE_CLUSTER_NAME") }, "context": "Default", "name": "rke_cluster_name" },
    { "value": { "value": os.getenv("PE_IP") }, "context": "Default", "name": "pe_ip" },
    { "value": { "value": os.getenv("PE_PORT") }, "context": "Default", "name": "pe_port" },
    { "value": { "value": os.getenv("PE_DATASERVICE_IP") }, "context": "Default", "name": "pe_dataservice_ip" },
    { "value": { "value": os.getenv("PE_STORAGE_CONTAINER") }, "context": "Default", "name": "pe_storage_container" }
]
