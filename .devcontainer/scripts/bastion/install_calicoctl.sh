#!/bin/bash
set -e
set -o pipefail

CALICOCTL_VERSION=v3.21.4

wget https://github.com/projectcalico/calicoctl/releases/download/${CALICOCTL_VERSION}/calicoctl
chmod +x calicoctl
mv calicoctl /usr/local/bin/

calicoctl -h