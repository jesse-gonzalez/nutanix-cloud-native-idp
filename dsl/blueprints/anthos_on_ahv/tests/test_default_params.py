import os

variable_list = [
    { "value": { "value": os.getenv("ANTHOS_CLUSTER_NAME") }, "context": "Default", "name": "ANTHOS_CLUSTER_NAME" },
    { "value": { "value": os.getenv("ANTHOS_CONTROLPLANE_VIP") }, "context": "Default", "name": "ANTHOS_CONTROLPLANE_VIP" },
    { "value": { "value": os.getenv("ANTHOS_PODS_NETWORK") }, "context": "Default", "name": "ANTHOS_PODS_NETWORK" },
    { "value": { "value": os.getenv("ANTHOS_SERVICES_NETWORK") }, "context": "Default", "name": "ANTHOS_SERVICES_NETWORK" },
    { "value": { "value": os.getenv("ANTHOS_INGRESS_VIP") }, "context": "Default", "name": "ANTHOS_INGRESS_VIP" },
    { "value": { "value": os.getenv("ANTHOS_LB_ADDRESSPOOL") }, "context": "Default", "name": "ANTHOS_LB_ADDRESSPOOL" },
    { "value": { "value": os.getenv("KUBERNETES_SERVICE_ACCOUNT") }, "context": "Default", "name": "KUBERNETES_SERVICE_ACCOUNT" },
    { "value": { "value": os.getenv("OS_DISK_SIZE") }, "context": "Default", "name": "OS_DISK_SIZE" },
    { "value": { "value": os.getenv("PYTHON_ANTHOS_GENCONFIG") }, "context": "Default", "name": "PYTHON_ANTHOS_GENCONFIG" },
    { "value": { "value": os.getenv("NTNX_CSI_URL") }, "context": "Default", "name": "NTNX_CSI_URL" },
    { "value": { "value": os.getenv("NTNX_PE_IP") }, "context": "Default", "name": "NTNX_PE_IP" },
    { "value": { "value": os.getenv("NTNX_PE_PORT") }, "context": "Default", "name": "NTNX_PE_PORT" },
    { "value": { "value": os.getenv("NTNX_PE_DATASERVICE_IP") }, "context": "Default", "name": "NTNX_PE_DATASERVICE_IP" },
    { "value": { "value": os.getenv("NTNX_PE_STORAGE_CONTAINER") }, "context": "Default", "name": "NTNX_PE_STORAGE_CONTAINER" },
    { "value": { "value": os.getenv("NTNX_PC_IP") }, "context": "Default", "name": "NTNX_PC_IP" },
    { "value": { "value": os.getenv("ANTHOS_VERSION") }, "context": "Default", "name": "ANTHOS_VERSION" }
]
