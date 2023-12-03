#!/bin/bash
set -e
set -o pipefail

TEMPDIR="$(mktemp -d)"
cd $TEMPDIR

CLI_TOOL_NAME="rancher"
VERSION="v2.6.5"
GITHUB_REPO_URL="https://github.com/rancher/cli"

OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
BINARY="${CLI_TOOL_NAME}-${OS}-${ARCH}-${VERSION}"
BIN_URL="${GITHUB_REPO_URL}/releases/download/${VERSION}/${BINARY}.tar.gz"

echo "Downloading ${CLI_TOOL_NAME} cli from $BIN_URL"

curl -fsSLO "${BIN_URL}"
tar zxvf "${BINARY}.tar.gz"
mv $TEMPDIR/${CLI_TOOL_NAME}-${VERSION}/${CLI_TOOL_NAME} /usr/local/bin
chmod +x /usr/local/bin/${CLI_TOOL_NAME}
ln -sn /usr/local/bin/${CLI_TOOL_NAME} /usr/bin/${CLI_TOOL_NAME}
