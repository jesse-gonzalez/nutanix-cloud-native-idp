# Download Calm DSL latest from hub.docker.com
FROM ntnx/calm-dsl:v3.5.2

LABEL org.opencontainers.image.title="nutanix-cloud-native-utils"
LABEL org.opencontainers.image.description="Cloud Native Utils built on top of Nutanix Calm DSL BASE"

# Target stable apk repo
# RUN echo 'https://dl-cdn.alpinelinux.org/alpine/v3.17/main' > /etc/apk/repositories \
#    && echo 'https://dl-cdn.alpinelinux.org/alpine/v3.17/community' >> /etc/apk/repositories

# Add packages needed for development
RUN apk update \
    && apk upgrade \
    && apk --no-cache add  \
        make \
        docker \
        git \
        curl \
        unzip \
        tar \
        openssl \
        gnupg \
        gpg \
        ca-certificates \
        tree \
        vim \
        gcompat \
        bash-completion \
        zsh \
        perl \
        ncurses \
        aws-cli \
        xorriso \
        libcap \
        skopeo \
        openssh-client \
        build-base \
        socat \
        sshpass \
        coreutils \
        python3 \
        py3-pip \
    && rm -rf /var/cache/apk/*

## configure azure-cli, ansible-navigator and other pip utils
RUN apk add --update --no-cache -q --virtual=build gcc musl-dev python3-dev libffi-dev openssl-dev cargo oniguruma-dev \
    && ln -sf python3 /usr/bin/python \
    && python3 -m ensurepip \
    && pip3 install --upgrade pip setuptools \
    && pip3 install --no-cache --no-cache-dir \
      azure-cli \
      shyaml \
      pre-commit \
      ggshield \
      ansible \
      diagrams \
      graphviz \
      ansible-navigator \
      -q \
     && apk del --purge build

## configure zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
    && git config --global --add safe.directory /dsl-workspace \
    && git config --global --add safe.directory /workspaces

## bring dotfiles for various shells over
COPY scripts/dotfiles /root

## install arkade
RUN curl -sLS https://get.arkade.dev | sh

## install cli tools via arkade
RUN arkade get \
      jq \
      yq \
      sops \
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
      clusterctl \
      kind \
      cilium \
      k10tools \
      k10multicluster \
      trivy \
      kubestr \
      oc \
      openshift-install \
      tkn \
    && mv /root/.arkade/bin/* /usr/local/bin \
    && rm -rf /tmp/*

## install krew plugins
RUN krew update \
    && krew install \
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
        cm \
        service-tree

# ## install utils
COPY scripts/bastion /tmp
WORKDIR /tmp
RUN chmod +x *.sh \
    && ./install_acme_client.sh \
    && ./install_helm_plugins.sh \
    && ./install_kube-ps1.sh \
    && ./install_calicoctl.sh \
    && ./install_rancher_cli.sh \
    && ./install_golang.sh \
    && ./install_velero_cli.sh \
    && ./install_eks_anywhere.sh \
    && ./install_roxctl.sh \
    && ./install_teller.sh \
    && ./install_d2.sh \
    && ./install_kubie.sh \
    && rm -rf /tmp/*

## configure calm completion and init
RUN calm completion install zsh \
    && mkdir -p /root/.calm \
    && touch /root/.calm/config.ini

## configure openssh-client with bare min.
RUN mkdir -p /root/.ssh \
    && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
    && echo "IdentityFile /root/.ssh/nutanix_key" >> /etc/ssh/ssh_config \
    && chmod 700 /root/.ssh

## preload zsh plugins
SHELL ["/bin/zsh", "-c"]
RUN source /root/.zshrc \
    &&  zsh -i -c -- 'zinit module build; @zinit-scheduler burst || true '
