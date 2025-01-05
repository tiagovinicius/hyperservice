# Function to restart hyperservice

service_restart() {
  local name="$1"
  local workdir="$2"

  echo "Restarting hyperservice: $name"

  if hyperservice_exists; then
    echo "Removing existing hyperservice: $NAME"
    docker rm -f "$NAME"
  fi
  echo "Creating and starting hyperservice: $NAME"
  docker run -d \
    --name "$NAME" \
    --volume "${LOCAL_WORKSPACE_FOLDER}:/workspace" \
    --volume "/etc/environment:/etc/environment:ro" \
    --workdir "/workspace/$WORKDIR" \
    --env-file "/etc/environment" \
    --env "KUMA_DPP=$NAME" \
    --env "DATA_PLANE_NAME=$NAME" \
    --env "CONTROL_PLANE_NAME=control-plane" \
    --network service-mesh \
    --privileged \
    hyper-dataplane-image

  echo "Hyperservice $name restarted successfully."
}
