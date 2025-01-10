#!/bin/bash

# Execute entrypoint.sh script
bash modules/kuma/control-plane-deployment/entrypoint.sh

# Execute build-image.sh script
bash modules/kuma/dataplane-deployment/build-image.sh

# Move docker-compose.yml to modules/kuma/control-plane-deployment
mv /workspace/.devcontainer/docker-compose.yml /workspace/modules/kuma/control-plane-deployment/docker-compose.yml
