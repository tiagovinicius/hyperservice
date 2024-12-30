FROM ubuntu:24.04

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    sudo build-essential git curl

RUN echo "Setup Kuma" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

WORKDIR /workspace

CMD ["kuma-cp", "run"]