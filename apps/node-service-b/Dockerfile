FROM node:22

# Instalação do npm
COPY package*.json ./

# Copia o código da aplicação
COPY . .


RUN echo "Setup Kuma to use CLIs" && \
    curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh - && \
    mv kuma-2.9.2/bin/* /usr/local/bin/
    
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]