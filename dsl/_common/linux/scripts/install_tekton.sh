
#!/bin/bash
set -e
set -o pipefail

# Get the tar.xz
curl -LO https://github.com/tektoncd/cli/releases/download/v0.29.1/tkn_0.29.1_Linux_x86_64.tar.gz
# Extract tkn to your PATH (e.g. /usr/local/bin)
tar xvzf tkn_0.29.1_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
sudo chmod +x /usr/local/bin/tkn

tkn help
