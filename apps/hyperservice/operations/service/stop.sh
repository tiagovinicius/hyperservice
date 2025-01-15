# Function to stop hyperservice

service_stop() {
  local name="$1"

  echo "Stopping hyperservice: $name"

  if hyperservice_exists; then
    CONTAINERS=$(docker ps -q --filter "name=^$NAME(-.*|$)")
    echo "$CONTAINERS" | while read -r container_id; do
      echo "Stopping container: $container_id"
      docker stop "$container_id"
    done
  else
    echo "Error: Hyperservice '$NAME' does not exist."
    exit 1
  fi

  CONTAINERS=$(docker ps -q --filter "name=^$NAME")

  echo "Hyperservice $name stopped successfully."
}
