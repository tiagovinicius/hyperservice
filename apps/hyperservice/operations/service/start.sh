# Function to start hyperservice

service_start() {
  local name="$1"
  local workdir="$2"

  echo "Starting hyperservice: $name"
  
  if hyperservice_exists; then
    echo "Starting existing hyperservice: $NAME"
    docker start "$NAME"
  else
    echo "Creating and starting hyperservice: $NAME"
    docker run -d \
      --name "$NAME" \
      --volume "${LOCAL_WORKSPACE_FOLDER}:/workspace" \
      --volume "/etc/environment:/etc/environment:ro" \
      --workdir "/workspace/$WORKDIR" \
      --env-file "/etc/environment" \
      --env "KUMA_DPP=$NAME" \
      --env "DATAPLANE_NAME=$NAME" \
      --env "CONTROL_PLANE_NAME=control-plane" \
      --network service-mesh \
      --privileged \
      hyper-dataplane-image
  fi

  echo "Hyperservice $name started successfully."
}
