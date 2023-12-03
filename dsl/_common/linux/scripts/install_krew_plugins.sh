echo "export PATH=\${PATH}:\${HOME}/.krew/bin" | tee -a ~/.bashrc ~/.zshrc

krew update
krew install \
  access-matrix \
  images \
  allctx \
  ca-cert \
  cert-manager \
  whoami \
  config-cleanup \
  karbon \
  popeye \
  df-pv \
  topology \
  service-tree