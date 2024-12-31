FROM ubuntu:24.04

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    sudo build-essential git docker.io docker-compose

RUN echo "Installing Node environment" && \
    sudo apt-get install -y nodejs npm

RUN echo "Install Python environment" && \
    apt-get install -y python3 python3-pip \
    python3-setuptools python3-distutils-extra

RUN echo "Setup Kuma to use CLIs" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

RUN echo "Setting workspace dir"
WORKDIR /workspace

RUN echo "Copying apps code"
COPY . .

# Inicie o Docker daemon
CMD ["dockerd-entrypoint.sh"]