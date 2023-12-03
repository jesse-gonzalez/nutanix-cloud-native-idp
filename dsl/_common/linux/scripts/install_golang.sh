# install golang for testing / development
wget https://golang.org/dl/go1.19.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz

echo "export PATH=\$PATH:/usr/local/go/bin" | tee -a ~/.bashrc ~/.zshrc

export PATH=$PATH:/usr/local/go/bin

# validate
go version
