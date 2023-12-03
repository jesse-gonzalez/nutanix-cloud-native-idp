# install bash-completion if not already done
sudo yum install -y bash-completion

# configure default .kube config path
sudo mkdir -p ~/.kube
sudo chown $(id -u):$(id -g) $HOME/.kube
touch $HOME/.kube/config
chmod 0600 $HOME/.kube/config

# configure bashrc
echo 'alias reload="source ~/.bashrc"' | tee -a ~/.bashrc ~/.zshrc
echo "source <(kubectl completion bash)" | tee -a ~/.bashrc ~/.zshrc
echo "alias k='kubectl'" | tee -a ~/.bashrc ~/.zshrc
echo "complete -F __start_kubectl k" | tee -a ~/.bashrc ~/.zshrc
echo "export do='--dry-run=client -o yaml'"  | tee -a ~/.bashrc ~/.zshrc

# add kubens and kubectx aliases
echo "alias kns='kubens'" | tee -a ~/.bashrc ~/.zshrc
echo "alias kctx='kubectx'" | tee -a ~/.bashrc ~/.zshrc

# install fzf command to switch between contexts easily

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all
echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' | tee -a ~/.bashrc

# stern config
echo 'alias stern="stern --tail 10 --since 5s"' | tee -a ~/.bashrc ~/.zshrc

# enable terraform tab completion

terraform -install-autocomplete
