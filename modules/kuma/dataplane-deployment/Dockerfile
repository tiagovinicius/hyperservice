FROM node:22

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    curl gettext-base wget jq coreutils \
    sudo nano iptables iptables-persistent nftables

RUN echo "Setup Kuma to use CLIs" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
 