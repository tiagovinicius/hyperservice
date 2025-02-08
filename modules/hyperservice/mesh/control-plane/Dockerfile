FROM node:22

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
        sudo build-essential git docker.io docker-compose \
        jq wget curl rsync

RUN echo "Setup Kuma to use CLIs" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/

EXPOSE 80

COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]