# change working directory
cd rke-on-ahv/terraform

echo 'ntnx_pe_subnet_name="Primary"

rke_cluster_name="@@{rke_cluster_name}@@"
amount_of_rke_worker_vms=2

#prism central credentials
ntnx_pc_ip="@@{pc_instance_ip}@@"
ntnx_pc_username="@@{Prism Central User.username}@@"
ntnx_pc_password="@@{Prism Central User.secret}@@"

#csi
ntnx_pe_storage_container="@@{pe_storage_container}@@"
ntnx_pe_username="@@{Prism Element User.username}@@"
ntnx_pe_password="@@{Prism Element User.secret}@@"
ntnx_pe_ip="@@{pe_cluster_vip}@@"
ntnx_pe_dataservice_ip="@@{pe_dataservices_vip}@@"' > terraform.tfvars

terraform init
