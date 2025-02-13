FROM node:22

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    bash build-essential coreutils curl \
    fzf iproute2 nmap collectd \
    iptables iptables-persistent jq nano needrestart \
    nftables sudo tar unzip uuid uuid-runtime wget yq


RUN echo "Setup Kuma to use CLIs" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

RUN npm install --global @moonrepo/cli

RUN sudo ln -sf /usr/bin/bash /usr/bin/sh

COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
 