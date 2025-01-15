# Function to start hyperservice

service_start() {
  local name="$1"
  local workdir="$2"

  echo "Starting hyperservice: $name"

  if [[ -f "$workdir/.hyperservice/fleet.yml" ]]; then
    echo "fleet.yml found. Creating fleet simulation."
    local units
    units=$(yq -r '.simulator.units' "$workdir/.hyperservice/fleet.yml")

    for ((i = 1; i <= units; i++)); do
      local base_name="${name}-$(uuidgen | cut -c1-8)"
      local node_name="${base_name}-node"
      local hyperservice_name="${base_name}"
      echo "Creating and starting fleet unit simulation: $node_name"
      docker_container_run "$node_name" \
        --volume "/var/run/docker.sock:/var/run/docker.sock" \
        --volume "/workspace:/workspace" \
        --volume "/etc/shared/environment:/etc/shared/environment" \
        --env "KUMA_DPP=$hyperservice_name" \
        --env "DATAPLANE_NAME=$hyperservice_name" \
        --env "WORKSPACE_FOLDER=$WORKSPACE_FOLDER" \
        --network service-mesh \
        hyperservice-fleet-simulator-image

      echo "Accessing fleet unit simulation: $node_name"
      wait_for_docker $node_name 60
      if [[ $? -eq 0 ]]; then
        echo "Fleet unit is ready. Running further commands..."
        echo "Creating and starting hypeservice: $hyperservice_name"
        docker exec $node_name \
        docker_container_run "$hyperservice_name" \
          --volume "/var/run/docker.sock:/var/run/docker.sock" \
          --volume "/workspace:/workspace" \
          --volume "/etc/shared/environment:/etc/shared/environment" \
          --workdir "/workspace/$workdir" \
          --env "KUMA_DPP=$hyperservice_name" \
          --env "DATAPLANE_NAME=$hyperservice_name" \
          --env "SERVICE_NAME=$NAME" \
          --env "WORKSPACE_FOLDER=$WORKSPACE_FOLDER" \
          --network service-mesh \
          --privileged \
          hyperservice-dataplane-image
      else
        echo "Failed to connect to the fleet unit: $container_name"
      fi

    done
  else
    if docker_container_exists "$NAME"; then
      echo "Starting existing hyperservice: $NAME"
      docker_container_start "$NAME"
    else
      echo "Creating and starting hyperservice: $NAME"
      docker_container_run "$NAME" \
        --volume "/workspace:/workspace" \
        --volume "/etc/shared/environment:/etc/shared/environment" \
        --workdir "/workspace/$WORKDIR" \
        --env "KUMA_DPP=$NAME" \
        --env "DATAPLANE_NAME=$NAME" \
        --env "SERVICE_NAME=$NAME" \
        --env "WORKSPACE_FOLDER=$WORKSPACE_FOLDER" \
        --network service-mesh \
        --privileged \
        hyperservice-dataplane-image
    fi
  fi

  echo "Hyperservice $name started successfully."
}
