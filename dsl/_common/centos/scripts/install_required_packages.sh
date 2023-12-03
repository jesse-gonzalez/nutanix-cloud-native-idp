echo "Install Packages"
sudo yum install epel-release -y
sudo yum update -y

echo "Install Latest Git Repos"
sudo yum -y install \
https://repo.ius.io/ius-release-el7.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

echo "Install Required Packages"
sudo yum -y install \
    sshpass \
    gcc \
    git \
    wget \
    unzip \
    tree \
    tar \
    openssl \
    openssl-devel \
    socat \
    make
