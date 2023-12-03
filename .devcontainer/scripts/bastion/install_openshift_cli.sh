#!/bin/bash
set -e
set -o pipefail

# Download Openshift Installer
curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-install-linux.tar.gz" | tar xz -C /tmp
mv /tmp/openshift-install /usr/local/bin
chmod +x /usr/local/bin/openshift-install

openshift-install -h

# Download Openshift Client
curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" | tar xz -C /tmp
mv /tmp/oc /usr/local/bin
chmod +x /usr/local/bin/oc

oc -h

# Install and configure Cloud Credential Operator utility
curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/ccoctl-linux.tar.gz" | tar xz -C /tmp
mv /tmp/ccoctl /usr/local/bin
chmod +x /usr/local/bin/ccoctl

ccoctl nutanix --help

# Install and configure Openshift Mirror Registry
# curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-4.11/oc-mirror.tar.gz" | tar xz -C /tmp
# mv /tmp/oc-mirror /usr/local/bin
# chmod +x /usr/local/bin/oc-mirror

# Install and configure Openshift Mirror Plugin