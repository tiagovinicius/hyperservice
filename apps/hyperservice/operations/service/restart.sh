# Function to restart hyperservice

service_restart() {
  local name="$1"
  local workdir="$2"

  echo "Restarting hyperservice: $name"

  if hyperservice_exists; then
    echo "Removing existing hyperservice: $NAME"
    docker rm -f "$NAME"
  fi

  if [[ -f "$workdir/.hyperservice/fleet.yml" ]]; then
    echo "fleet.yml found. Creating multiple containers."
    local units
    units=$(yq e '.simulator.units' "$workdir/.hyperservice/fleet.yml")

    for ((i = 1; i <= units; i++)); do
      local container_name="${name}-$(uuidgen | cut -c1-8)"
      echo "Creating and starting container: $container_name"
      docker run -d \
        --name "$container_name" \
        --volume "/workspace:/workspace" \
        --volume "/etc/shared/environment:/etc/shared/environment" \
        --workdir "/workspace/$workdir" \
        --env "KUMA_DPP=$container_name" \
        --env "DATAPLANE_NAME=$container_name" \
        --env "WORKSPACE_FOLDER=$WORKSPACE_FOLDER" \
        --network service-mesh \
        --privileged \
        docker:latest

      echo "Running docker run inside container: $container_name"
      docker exec "$container_name" docker run -d --name "inner-$container_name" alpine:latest sleep 3600
    done
  else
    echo "Creating and starting hyperservice: $NAME"
    docker run -d \
      --name "$NAME" \
      --volume "/workspace:/workspace" \
      --volume "/etc/shared/environment:/etc/shared/environment" \
      --workdir "/workspace/$WORKDIR" \
      --env "KUMA_DPP=$NAME" \
      --env "DATAPLANE_NAME=$NAME" \
      --env "WORKSPACE_FOLDER=$WORKSPACE_FOLDER" \
      --network service-mesh \
      --privileged \
      hyper-dataplane-image
  fi

  echo "Hyperservice $name restarted successfully."
}
