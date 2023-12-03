## configure acme shell
## https://github.com/acmesh-official/acme.sh

curl https://get.acme.sh | sh

echo 'alias acme.sh=$HOME/.acme.sh/acme.sh' | tee -a ~/.bashrc ~/.zshrc