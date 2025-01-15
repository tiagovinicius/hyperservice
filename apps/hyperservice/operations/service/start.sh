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

  echo "Hyperservice $name started successfully."
}
