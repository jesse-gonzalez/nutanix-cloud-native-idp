RKE2_SERVER=@@{ControlPlaneVMs.address}@@
NODE_TOKEN=@@{ControlPlaneVMs.agent_node_token}@@

# install rke2-server
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="agent" sh -

# configure rke2 node token in config file

mkdir -p /etc/rancher/rke2/

echo "server: https://`echo $RKE2_SERVER`:9345" | sudo tee -a /etc/rancher/rke2/config.yaml
echo "token: `echo $NODE_TOKEN`" | sudo tee -a /etc/rancher/rke2/config.yaml

sudo cat /etc/rancher/rke2/config.yaml

# enable and start server service
sudo systemctl enable rke2-agent
sudo systemctl start rke2-agent


# troubleshooting
#journalctl -u rke2-agent -f
