#!/bin/bash

# Verificar se a rede existe
if [ -n "$(docker network ls --filter name=^service-mesh$ --format '{{.Name}}')" ]; then
    echo "Network 'service-mesh' found. Recreating the network..."

    # Obtém a lista de containers conectados à rede 'service-mesh'
    containers=$(docker network inspect service-mesh --format '{{range .Containers}}{{.Name}} {{end}}')

    # Obtém o hostname do DevContainer
    host_container_id=$(hostname)
    host_container_name=$(docker ps --format '{{.ID}} {{.Names}}' | grep "^$host_container_id " | awk '{print $2}')

    if [ -n "$containers" ]; then
        echo "Stopping containers connected to 'service-mesh' (except host container: $host_container_name):"
        
        for container in $containers; do
            if [ "$container" != "$host_container_name" ]; then
                echo "Stopping $container..."
                docker stop "$container"
            else
                echo "Skipping host container: $container"
            fi
        done
    else
        echo "No containers found in the 'service-mesh' network."
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