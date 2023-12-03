#!/bin/bash
set -e
set -o pipefail

curl --silent --location "https://github.com/tellerops/teller/releases/download/v1.5.6/teller_1.5.6_Linux_x86_64.tar.gz" | tar xz -C /tmp
mv /tmp/teller /usr/local/bin/teller
chmod +x /usr/local/bin/teller

teller --help
