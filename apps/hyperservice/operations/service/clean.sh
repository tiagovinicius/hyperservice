# Function to clean hyperservice

service_clean() {
  local name="$1"

  echo "Cleaning hyperservice: $name"

  # Check if the hyperservice exists
  if ! docker_container_exists "$name"; then
    echo "Hyperservice $name does not exist."
    return
  fi

  # Stop the hyperservice if it is running
  if docker_container_exists "$name"; then
    echo "Stopping hyperservice: $name"
    docker_container_stop "$name"
  fi

  # Remove the hyperservice containers
  if docker_container_exists "$name"; then
    echo "Removing containers for hyperservice: $name"
    docker_container_remove "$name"
  fi

  echo "Hyperservice $name cleaned successfully."
}
