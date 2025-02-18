#!/bin/bash
set -e

# Check if the network exists
if [ -n "$(docker network ls --filter name=^hy-bridge$ --format '{{.Name}}')" ]; then
    echo "🔍 Network 'hy-bridge' found. Recreating the network..."

    # Get the hostname of the DevContainer
    host_container_id=$(hostname)
    host_container_name=$(docker ps --format '{{.ID}} {{.Names}}' | grep "^$host_container_id " | awk '{print $2}')
    if docker network inspect hy-bridge | grep -q "$host_container_name"; then
        echo "⏳ Disconnecting DevContainer ($host_container_name) from 'hy-bridge'..."
        docker network disconnect hy-bridge "$host_container_name"
    else
        echo "⚠️ DevContainer ($host_container_name) is not connected to 'hy-bridge'. Skipping disconnect."
    fi

    # Get the list of containers connected to the 'hy-bridge' network
    containers=$(docker network inspect hy-bridge --format '{{range .Containers}}{{.Name}} {{end}}')

    if [ -n "$containers" ]; then
        echo "⏳ Stopping containers connected to 'hy-bridge':"
        
        for container in $containers; do
            echo "⏳ Stopping $container..."
            docker stop "$container"
        done
    else
        echo "✅ No containers found in the 'hy-bridge' network."
    fi

    # Remove the network
    echo "⏳ Removing network 'hy-bridge'..."
    docker network rm hy-bridge
    echo "✅🧹 Network 'hy-bridge' removed."
fi

# Create the new network
echo "⏳ Creating new network 'hy-bridge'..."
docker network create \
    --subnet=192.168.1.0/24 \
    --gateway=192.168.1.1 \
    hy-bridge
echo "✅🌐 Network 'hy-bridge' created successfully."

# Connect the DevContainer to the network
echo "⏳ Connecting DevContainer ($host_container_name) to 'hy-bridge'..."
docker network connect hy-bridge $(hostname)
echo "✅🔌 DevContainer connected to 'hy-bridge'."