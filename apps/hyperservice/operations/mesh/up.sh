#!/bin/bash
mesh_up() {
    # Execute build-image.sh script
    bash modules/kuma/dataplane-deployment/build-image.sh
    docker-compose -f modules/kuma/control-plane-deployment/docker-compose.yml up
} 