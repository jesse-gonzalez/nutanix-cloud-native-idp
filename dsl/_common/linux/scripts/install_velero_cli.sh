# Download Velero CLI Installer
curl --silent --location "https://github.com/vmware-tanzu/velero/releases/download/v1.10.0/velero-v1.10.0-linux-amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/velero-v1.10.0-linux-amd64/velero /usr/local/bin
sudo chmod +x /usr/local/bin/velero

velero --help
