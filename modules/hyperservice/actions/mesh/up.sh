#!/bin/bash
mesh_up() {
    # Execute build-image.sh script
    bash modules/hyperservice/mesh/dataplane/build-image.sh
    bash modules/hyperservice/fleet-simulator/build-image.sh
    docker network create service-mesh
    docker-compose -f modules/hyperservice/mesh/control-plane/docker-compose.yml up -d
} 