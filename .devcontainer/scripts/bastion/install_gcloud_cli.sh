#!/bin/bash
set -e
set -o pipefail

## shorter version of install script

curl https://sdk.cloud.google.com | bash /dev/stdin --disable-prompts
