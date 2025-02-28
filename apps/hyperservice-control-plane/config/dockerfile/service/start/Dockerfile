# Define uma imagem base com opção de argumento
ARG BASE_IMAGE=node:23-bookworm-slim
FROM ${BASE_IMAGE} AS base

# Instala dependências base
RUN echo "🛠 Installing base dependencies..." && \
    apt-get update && apt-get install -y \
    curl collectd git

# Verifica se o Node.js está instalado, caso contrário, instala manualmente
RUN if ! command -v node > /dev/null; then \
      echo "⚡ Node.js not found, installing manually..."; \
      curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
      apt-get install -y nodejs; \
    else \
      echo "✅ Node.js already installed!"; \
    fi

# Instala o Hyperservice Dataplane
RUN echo "🚀 Installing Hyperservice Dataplane..." && \
    curl -sL https://raw.githubusercontent.com/tiagovinicius/hyperservice/main/get-hy-dp.sh | bash

# Instala o Kuma
RUN echo "🔧 Installing Kuma..." && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.3 sh - && \
    mv kuma-2.9.3/bin/* /usr/local/bin/ && \
    rm -rf kuma-2.9.3

# Instala o Moonrepo CLI
RUN echo "🌙 Installing Moonrepo CLI..." && \
    curl -fsSL https://moonrepo.dev/install/moon.sh | bash && \
    mv "$HOME/.moon/bin/moon" /usr/local/bin/


# Define o comando de entrada
ENTRYPOINT ["hy-dp"]