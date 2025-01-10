#!/bin/bash
mesh_down() {
    # Stop docker-compose.yml in modules/kuma/control-plane-deployment
    docker-compose -f modules/kuma/control-plane-deployment/docker-compose.yml down
}
