
#!/bin/bash
set -e
set -o pipefail

curl --silent --location "https://mirror.openshift.com/pub/rhacs/assets/3.73.1/bin/Linux/roxctl" -o /tmp/roxctl
mv /tmp/roxctl /usr/local/bin/roxctl
chmod +x /usr/local/bin/roxctl

roxctl --help
