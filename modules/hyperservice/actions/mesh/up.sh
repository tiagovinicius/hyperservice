#!/bin/bash
mesh_up() {
    # Execute build-image.sh script
    bash modules/hyperservice/fleet/build-image.sh

    if [ -z "$(docker network ls --filter name=^service-mesh$ --format '{{.Name}}')" ]; then
        echo "Network 'service-mesh' not found. Creating the network..."
        docker network create service-mesh
        echo "Network 'service-mesh' created successfully."
        else
        echo "The network 'service-mesh' already exists."
    fi

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
    --health-cmd "bash -c '[[ \$(cat /etc/hyperservice/shared/environment/CONTROL_PLANE_STATUS 2>/dev/null) == \"running\" ]]'" \
    --health-interval=2s \
    --health-timeout=10s \
    --health-retries=5 \
    --health-start-period=3s \
   hyperservice-control-plane-image
   
} 