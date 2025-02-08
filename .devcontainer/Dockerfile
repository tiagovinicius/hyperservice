FROM node:22

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    bash build-essential coreutils curl \
    fzf gettext gettext-base iproute2 rsync \
    iptables iptables-persistent jq nano needrestart \
    nftables sshpass sudo tar unzip uuid uuid-runtime wget yq


RUN echo "Setup Kuma to use CLIs" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

RUN npm install --global @moonrepo/cli

RUN sudo ln -sf /usr/bin/bash /usr/bin/sh

ENTRYPOINT ["bash", "true"]
 