# Function to stop hyperservice

service_stop() {
  local name="$1"

  echo "Stopping hyperservice: $name"

  if hyperservice_exists; then
    docker stop "$NAME"
  else
    echo "Error: Hyperservice '$NAME' does not exist."
    exit 1
  fi

  echo "Hyperservice $name stopped successfully."
}
