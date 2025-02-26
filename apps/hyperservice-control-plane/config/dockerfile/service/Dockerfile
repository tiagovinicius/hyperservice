FROM node:23-bookworm-slim

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    curl collectd

# Install hyperservice Dataplane
RUN curl -sL https://raw.githubusercontent.com/tiagovinicius/hyperservice/main/get-hy-dp.sh | bash && \
chmod +x hy-dp && mv hy-dp /usr/local/bin/

# Install Kuma
RUN curl -L https://kuma.io/installer.sh | VERSION=2.9.3 sh - && \
    mv kuma-2.9.3/bin/* /usr/local/bin/ && \
    rm -rf kuma-2.9.3

# Install Moonrepo CLI
RUN curl -fsSL https://moonrepo.dev/install/moon.sh | bash && \
    mv "$HOME/.moon/bin/moon" /usr/local/bin/

ENTRYPOINT ["hy-dp"]
 