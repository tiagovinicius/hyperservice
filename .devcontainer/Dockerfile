FROM ubuntu:24.04

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    sudo build-essential git docker.io docker-compose python3 python3-pip python3-setuptools

RUN echo "Install python3-distutils-extra" && \
    apt-get install -y python3-distutils-extra

RUN echo "Setting workspace dir"
WORKDIR /workspace

RUN echo "Copying apps code"
COPY . .

# Inicie o Docker daemon
CMD ["dockerd-entrypoint.sh"]