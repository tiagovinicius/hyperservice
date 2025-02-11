#!/bin/bash
mesh_up() {
    # Execute build-image.sh script
    bash modules/hyperservice/fleet/build-image.sh

    bash modules/hyperservice/mesh/control-plane/build-image.sh

    if docker ps -q -f name=control-plane; then
    docker stop control-plane && docker rm control-plane
    fi

    docker run -d --name control-plane \
        --privileged \
        -v ${HYPERSERVICE_DEV_HOST_WORKSPACE_PATH}:/workspace:delegated \
        -v /etc/hyperservice/shared/environment:/etc/hyperservice/shared/environment \
        -v /etc/hyperservice/shared/ssh:/etc/hyperservice/shared/ssh \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ~/.ssh:/root/.ssh:rw \
        -p 5681:5681 \
        -p 8080:8080 \
        -p 5678:5678 \
        -p 5680:5680 \
        --health-cmd "bash -c '[[ \$(cat /etc/hyperservice/shared/environment/CONTROL_PLANE_STATUS 2>/dev/null) == \"running\" ]]'" \
        --health-interval=2s \
        --health-timeout=10s \
        --health-retries=5 \
        --health-start-period=3s \
        --network service-mesh \
        --ip 192.168.1.100 \
    hyperservice-control-plane-image
    until [ "$(docker inspect -f '{{.State.Health.Status}}' control-plane)" == "healthy" ]; do
        sleep 1
    done

    if [ "$(docker ps -q -f name=grafana)" ]; then
        echo "The container grafana is running. Stopping and removing it..."
        docker stop grafana
        docker rm grafana
    elif [ "$(docker ps -aq -f name=grafana)" ]; then
        echo "The container grafana exists but is not running. Removing it..."
        docker rm grafana
    fi
    docker run -d \
        --name grafana \
        -p 3000:3000 \
        --network service-mesh \
        --ip 192.168.1.103 \
        grafana/grafana:8.5.2

    if [ "$(docker ps -q -f name=prometheus)" ]; then
        echo "The container prometheus is running. Stopping and removing it..."
        docker stop prometheus
        docker rm prometheus
    elif [ "$(docker ps -aq -f name=prometheus)" ]; then
        echo "The container prometheus exists but is not running. Removing it..."
        docker rm prometheus
    fi
    docker run -d \
        --name prometheus \
        -p 9090:9090 \
        --health-cmd="wget --spider --quiet http://192.168.1.104:9090/-/healthy || exit 1" \
        --health-interval=30s \
        --health-timeout=5s \
        --health-retries=3 \
        -v /usr/local/bin/hyperservice-bin/common-services/observability/config:/etc/prometheus \
        --network service-mesh \
        --ip 192.168.1.104 \
        prom/prometheus

    services=(
        "control-plane:192.168.1.100:5680"
        "control-plane:192.168.1.100:5681"
        "control-plane:192.168.1.100:5676"
        "prometheus:192.168.1.104:9090"
    )

    for service in "${services[@]}"; do
        IFS=':' read -r container ip port <<< "$service"

        echo "Waiting for $container to become healthy..."
        until [ "$(docker inspect -f '{{.State.Health.Status}}' "$container")" == "healthy" ]; do
            sleep 1
        done
        echo "$container is healthy."

        echo "Checking for existing forwarding process on port $port..."
        pid=$(ss -tulwnp 2>/dev/null | grep :"$port" | awk '{print $NF}' | sed -n 's/.*pid=\([0-9]*\).*/\1/p')
        
        if [ -n "$pid" ]; then
            echo "Found forwarding process (PID: $pid) on port $port. Killing it..."
            kill -9 "$pid"
            echo "Killed forwarding process on port $port. Waiting for the port to be released..."
            sleep 2  # Give time for the system to free the port
        else
            echo "No forwarding process found on port $port."
        fi

        # Wait until the port is completely free
        while ss -tulwnp 2>/dev/null | grep -q :"$port"; do
            echo "Port $port still in use. Waiting..."
            sleep 1
        done

        echo "Starting forwarding on port $port (redirecting to $ip:$port)..."
        socat TCP-LISTEN:"$port",fork TCP:"$ip":"$port" &
        echo "Started forwarding on port $port."
    done
}
