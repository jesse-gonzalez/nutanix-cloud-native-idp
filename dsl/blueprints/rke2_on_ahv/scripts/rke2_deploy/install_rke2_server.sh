# Download and run default installer
curl -sfL https://get.rke2.io | sudo sh -

# enable and start server service
# Download and run default installer
curl -sfL https://get.rke2.io | sudo sh -

# enable and start rke2-server services
sudo systemctl enable rke2-server
sudo systemctl start rke2-server

# wait for node token and kubectl config files to be available
sudo sh -c "while [ ! -f /var/lib/rancher/rke2/server/node-token ]; do sleep 1; done"
sudo sh -c "while [ ! -f /etc/rancher/rke2/rke2.yaml ]; do sleep 1; done"

# set path to include rke2 bin
echo "export PATH=$PATH:/var/lib/rancher/rke2/bin/" >> $HOME/.bashrc
export PATH=$PATH:/var/lib/rancher/rke2/bin/

# configure kubectlcfg
mkdir $HOME/.kube
sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chmod 0644 $HOME/.kube/config

# validate with basic binary commands
kubectl config view --minify
kubectl cluster-info
kubectl get nodes -o wide
rke2 -h

## troubleshooting
## journalctl -u rke2-server -f
