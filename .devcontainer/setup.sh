#!/bin/bash

# Inicializar Dokku
echo "Inicializando Dokku..."
dokku plugin:install-dependencies

# Configurar Postgres
echo "Instalando plugin de Postgres para Dokku..."
dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres

# Configurar UI
echo "Instalando UI para Dokku..."
dokku plugin:install https://github.com/josegonzalez/dokku-ui.git

echo "Instalando Portainer para gerenciar Docker..."
docker run -d -p 9000:9000 --name portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    portainer/portainer-ce &

# Configurar Kuma
echo "Configurando Kuma Control Plane..."
kumactl install control-plane | bash
echo "Adicionando Kuma Control Plane à configuração..."
kumactl config control-planes add --name=local --address=http://localhost:5681 
echo "Adicionando Kuma Control Plane à configuração..."
kuma-cp run --mode universal --gui-enabled &

# Aguardar a conclusão dos processos
wait
echo "Todos os processos foram concluídos."