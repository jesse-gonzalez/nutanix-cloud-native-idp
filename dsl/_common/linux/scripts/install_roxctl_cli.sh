#!/bin/bash
set -e
set -o pipefail

curl --silent --location "https://mirror.openshift.com/pub/rhacs/assets/3.73.1/bin/Linux/roxctl" -o /tmp/roxctl
sudo mv /tmp/roxctl /usr/local/bin/roxctl
sudo chmod +x /usr/local/bin/roxctl

roxctl --help
