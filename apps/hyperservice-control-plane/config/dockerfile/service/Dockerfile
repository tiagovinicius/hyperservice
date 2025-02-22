FROM node:23-bookworm-slim

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    curl collectd

# Install Kuma
RUN curl -L https://kuma.io/installer.sh | VERSION=2.9.3 sh - && \
    mv kuma-2.9.3/bin/* /usr/local/bin/ && \
    rm -rf kuma-2.9.3

# Install Moonrepo CLI
RUN curl -fsSL https://moonrepo.dev/install/moon.sh | bash && \
    mv "$HOME/.moon/bin/moon" /usr/local/bin/

COPY ./offline-dependencies/bin/hy-dp/main /usr/local/bin/hy-dp
RUN chmod +x /usr/local/bin/hy-dp

COPY ./config/collectd.conf /etc/collectd/collectd.conf

ENTRYPOINT ["hy-dp"]
 