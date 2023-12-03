REQUIRED_TOOLS_LIST += packer

TARGET_OS ?= centos7

packer-ahv-validate packer-ahv-build: packer-ahv-init

.PHONY: packer-ahv-print-uuids
packer-ahv-print-uuids: #### Print ahv image uuids from existing terraform output / state file
	@echo PKR_VAR_centos7_iso_uuid=${PKR_VAR_centos7_iso_uuid}
	@echo PKR_VAR_centos8_iso_uuid=${PKR_VAR_centos8_iso_uuid}
	@echo PKR_VAR_rhel7_iso_uuid=${PKR_VAR_rhel7_iso_uuid}
	@echo PKR_VAR_rhel8_iso_uuid=${PKR_VAR_rhel8_iso_uuid}
	@echo PKR_VAR_windows_2016_iso_uuid=${PKR_VAR_windows_2016_iso_uuid}
	@echo PKR_VAR_virtio_iso_uuid=${PKR_VAR_virtio_iso_uuid}
	@echo PKR_VAR_ubuntu1804_iso_uuid=${PKR_VAR_ubuntu1804_iso_uuid}

.PHONY: packer-ahv-init
packer-ahv-init: #### Init packer ahv configs
	[ -f $(TF_AHV_IMAGE_STATE_PATH) ] || make terraform-apply TF_PATH=ahv/upload-images ENVIRONMENT=${ENVIRONMENT}
	@make packer-ahv-print-uuids ENVIRONMENT=${ENVIRONMENT}; \
		cd packer/ahv/${TARGET_OS}; \
		packer init -upgrade .

.PHONY: packer-ahv-validate
packer-ahv-validate: #### Validates Packer Build Files. i.e., make packer-ahv-validate TARGET_OS=windows2016 ENVIRONMENT=${ENVIRONMENT}
	@cd packer/ahv/${TARGET_OS}; \
		packer validate .

.PHONY: packer-ahv-build
packer-ahv-build: #### Builds Target Packer Image. i.e., make packer-ahv-build TARGET_OS=windows2016 ENVIRONMENT=${ENVIRONMENT}
	@cd packer/ahv/${TARGET_OS}; \
		packer build -force -on-error=cleanup .

.PHONY: packer-vsphere-build
packer-vsphere-build: #### Builds vSphere VM Templates. i.e., make packer-vsphere-build TARGET_OS=windows10 ENVIRONMENT=${ENVIRONMENT}
	@cd packer/vsphere/${TARGET_OS}; \
		packer init -upgrade . \
		packer validate . \
		packer build -force -on-error=cleanup .
