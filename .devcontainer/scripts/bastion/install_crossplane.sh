#!/bin/bash
set -e
set -o pipefail

# install crossplane cli
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh

mv kubectl-crossplane /usr/local/bin
kubectl crossplane --help
