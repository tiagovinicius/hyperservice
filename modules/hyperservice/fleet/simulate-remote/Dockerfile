FROM node:22

ENV HYPERSERVICE_OFFLINE_INSTALL=false

RUN apt-get update && \
    apt-get install -y openssh-server sudo \
    bash build-essential coreutils curl \
    fzf iproute2 rsync \
    iptables iptables-persistent jq nano needrestart \
    nftables sudo tar unzip uuid uuid-runtime wget yq

RUN echo "Setup Kuma to use CLIs" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

RUN npm install --global @moonrepo/cli

RUN rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
    && echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config \
    && echo 'AuthorizedKeysFile %h/.ssh/authorized_keys' >> /etc/ssh/sshd_config

RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Criação do usuário personalizado com permissão sudo
RUN useradd -m -s /bin/bash -G sudo user && echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

EXPOSE 22

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
