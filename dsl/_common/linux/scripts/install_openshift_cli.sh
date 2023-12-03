#ALT: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable
OCP_VERSION="4.13.4"

# Download Openshift Installer
curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux.tar.gz" | tar xz -C /tmp
sudo mv /tmp/openshift-install /usr/local/bin
sudo chmod +x /usr/local/bin/openshift-install

openshift-install -h

# Download Openshift Client
curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux.tar.gz" | tar xz -C /tmp
sudo mv /tmp/oc /usr/local/bin
sudo chmod +x /usr/local/bin/oc

oc -h

# install and configure Cloud Credential Operator utility
curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/ccoctl-linux.tar.gz" | tar xz -C /tmp
sudo mv /tmp/ccoctl /usr/local/bin
sudo chmod +x /usr/local/bin/ccoctl

ccoctl nutanix --help