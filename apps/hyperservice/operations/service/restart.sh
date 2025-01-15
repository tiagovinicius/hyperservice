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
    --volume "/workspace:/workspace" \
    --volume "/etc/shared/environment:/etc/shared/environment" \
    --workdir "/workspace/$WORKDIR" \
    --env "KUMA_DPP=$NAME" \
    --env "DATAPLANE_NAME=$NAME" \
    --env "WORKSPACE_FOLDER=$WORKSPACE_FOLDER" \
    --network service-mesh \
    --privileged \
    hyper-dataplane-image

  echo "Hyperservice $name restarted successfully."
}
