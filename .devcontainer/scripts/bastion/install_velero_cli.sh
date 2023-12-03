#!/bin/bash
set -e
set -o pipefail

# Download Velero CLI Installer
curl --silent --location "https://github.com/vmware-tanzu/velero/releases/download/v1.10.0/velero-v1.10.0-linux-amd64.tar.gz" | tar xz -C /tmp
mv /tmp/velero-v1.10.0-linux-amd64/velero /usr/local/bin
chmod +x /usr/local/bin/velero

velero --help
