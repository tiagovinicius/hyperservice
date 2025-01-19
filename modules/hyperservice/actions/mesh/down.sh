#!/bin/bash
mesh_down() {
    # Stop docker-compose.yml in modules/hyperservice/mesh/control-plane
    docker-compose -f modules/hyperservice/mesh/control-plane/docker-compose.yml down
}
