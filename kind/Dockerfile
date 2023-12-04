FROM kindest/node:v1.22.5

## need to fix apt sources first
RUN sed -i -r 's/([a-z]{2}.)?archive.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list \
    && sed -i -r 's/security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
      open-iscsi \
      nfs-common \
      fdisk \
      xfsprogs

RUN systemd-tmpfiles --create

RUN systemctl enable iscsid \
    && systemctl enable open-iscsi


