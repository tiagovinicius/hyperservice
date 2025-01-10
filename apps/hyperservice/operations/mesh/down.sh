#!/bin/bash

# Stop docker-compose.yml in modules/kuma/control-plane-deployment
docker-compose -f /workspace/modules/kuma/control-plane-deployment/docker-compose.yml down
