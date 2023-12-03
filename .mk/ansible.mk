REQUIRED_TOOLS_LIST += ansible ansible-galaxy ansible-playbook ansible-vault

install-ansible-ncp-collection:
	ansible-galaxy collection install nutanix.ncp