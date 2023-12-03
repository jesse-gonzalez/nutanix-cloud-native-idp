## install cloud-native tools via arkade
arkade get \
  jq \
  yq \
  helm \
  kustomize \
  kubectl \
  kubectx \
  kubens \
  krew \
  stern \
  argocd \
  istioctl \
  oh-my-posh \
  packer \
  terraform \
  vagrant \
  vault \
  mkcert \
  helmfile \
  flux \
  fzf \
  gh \
  eksctl \
  clusterctl \
  kind \
  cilium \
  k10tools \
  k10multicluster \
  trivy

## sops \

## move from temp to bin
sudo mv $HOME/.arkade/bin/* /usr/local/bin

## cleanup
sudo rm -rf /tmp/*