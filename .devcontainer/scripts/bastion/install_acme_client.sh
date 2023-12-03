#!/bin/bash
set -e
set -o pipefail

## https://github.com/acmesh-official/acme.sh

curl https://get.acme.sh | sh -s email=admin@no-reply.com
