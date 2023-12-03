#!/bin/bash
set -e
set -o pipefail

# update kubeconfig to support multiple clusters

## updating bashrc to loop through kubeconfig files from all clusters and add to overall context"
echo "#######"
echo "if [ -f \$HOME/.kube/*.cfg ]; then" | tee -a ~/.bashrc ~/.zshrc
echo "  export KUBECONFIG_LIST=\$(ls \$HOME/.kube/*.cfg | xargs -n 1 basename | xargs -I {} echo -n \$HOME/.kube/{} )" | tee -a ~/.bashrc ~/.zshrc
echo "  export KUBECONFIG=$( echo \$KUBECONFIG_LIST | tr ' ' ':' )" | tee -a ~/.bashrc ~/.zshrc
echo "  kubectl config view --flatten >| \$HOME/.kube/config && chmod 600 \$HOME/.kube/config" | tee -a ~/.bashrc ~/.zshrc ## merge configs to standalone config file
echo "  export KUBECONFIG=\$HOME/.kube/config" | tee -a ~/.bashrc ~/.zshrc ## reset kubeconfig path
echo "  kubectl config-cleanup --clusters --users --print-removed -o=jsonpath='{ range.contexts[*] }{ .context.cluster }{\"\\n\"}' -t 2 | xargs -I {} rm -f ~/.kube/{}.cfg"  | tee -a ~/.bashrc ~/.zshrc # cleanup any configs that are no longer accessible
echo "  chmod 600 \$HOME/.kube/config \$HOME/.kube/*.cfg"
echo "fi" | tee -a ~/.bashrc ~/.zshrc
echo "#######"