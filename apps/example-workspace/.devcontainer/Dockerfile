FROM node:22

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    bash build-essential coreutils curl \
    fzf iproute2 nmap collectd \
    iptables iptables-persistent jq nano needrestart \
    nftables sudo tar unzip uuid uuid-runtime wget yq

# Install K3d
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Kuma
RUN curl -L https://kuma.io/installer.sh | VERSION=2.9.3 sh - && \
    mv kuma-2.9.3/bin/* /usr/local/bin/

# Install Moonrepo CLI
RUN npm install --global @moonrepo/cli

RUN sudo ln -sf /usr/bin/bash /usr/bin/sh

ENTRYPOINT ["bash", "true"]
 