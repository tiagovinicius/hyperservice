FROM kong:latest

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    sudo build-essential git curl gettext-base

RUN echo "Setup Kuma" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]