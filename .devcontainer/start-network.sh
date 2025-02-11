#!/bin/bash

# Verificar se a rede existe
if [ -n "$(docker network ls --filter name=^service-mesh$ --format '{{.Name}}')" ]; then
    echo "Network 'service-mesh' found. Recreating the network..."

    # Listar todos os containers conectados à rede e parar cada um deles
    containers=$(docker network inspect service-mesh --format '{{range .Containers}}{{.Name}} {{end}}')
    if [ -n "$containers" ]; then
        echo "Stopping containers connected to 'service-mesh': $containers"
        for container in $containers; do
            docker stop "$container"
        done
    fi

    # Remover a rede
    docker network rm service-mesh
    echo "Network 'service-mesh' removed."
fi

# Criar a nova rede
docker network create --subnet=192.168.1.0/24 service-mesh
echo "Network 'service-mesh' created successfully."

# Conectar o DevContainer à rede
docker network connect service-mesh $(hostname)
echo "DevContainer connected to 'service-mesh'."