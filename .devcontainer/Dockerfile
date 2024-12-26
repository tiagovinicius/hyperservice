FROM ubuntu:22.04

# # Instalação de dependências básicas
# RUN apt-get update && apt-get install -y \
#     curl software-properties-common git docker.io \
#     docker-compose unzip wget

# # Configuração do Dokku
# RUN wget https://raw.githubusercontent.com/dokku/dokku/v0.30.1/bootstrap.sh && \
#     DOKKU_TAG=v0.30.1 bash bootstrap.sh

# # Instalação do Kuma
# RUN curl -L https://kuma.io/installer.sh | sh && \
#     cp /opt/kuma/bin/kumactl /usr/local/bin/kumactl

# # Configuração do Kuma para modo universal
# RUN /opt/kuma/bin/kuma-cp run --mode universal &

# EXPOSE 80 443 5681 5682