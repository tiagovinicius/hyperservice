# Function to clean hyperservice

service_clean() {
  local name="$1"

  echo "Cleaning hyperservice: $name"

  # Check if the hyperservice exists
  if ! hyperservice_exists "$name"; then
    echo "Hyperservice $name does not exist."
    return
  fi

  # Stop the hyperservice if it is running
  if docker ps -q --filter "name=^$name(-.*|$)" | grep -q .; then
    echo "Stopping hyperservice: $name"
    docker ps -q --filter "name=^$name(-.*|$)" | while read -r container_id; do
      echo "Stopping container: $container_id"
      docker stop "$container_id"
    done
  fi

  # Remove the hyperservice containers
  if docker ps -a -q --filter "name=^$name(-.*|$)" | grep -q .; then
    echo "Removing containers for hyperservice: $name"
    docker ps -a -q --filter "name=^$name(-.*|$)" | while read -r container_id; do
      echo "Removing container: $container_id"
      docker rm "$container_id"
    done
  fi

  echo "Hyperservice $name cleaned successfully."
}
