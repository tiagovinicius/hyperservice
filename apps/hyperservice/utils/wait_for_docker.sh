#!/bin/bash

# Function to wait for a Docker container to become available
wait_for_docker() {
  local container_name="$1"
  local timeout="${2:-60}" # Default timeout is 60 seconds

  # Ensure a container name is provided
  if [[ -z "$container_name" ]]; then
    echo "Error: Container name is required."
    echo "Usage: wait_for_docker <container_name> [timeout]"
    return 1
  fi

  echo "Waiting for container '$container_name' to become available..."

  local elapsed=0

  # Function to check if Docker is ready
  is_docker_ready() {
    docker exec "$container_name" echo "ready" >/dev/null 2>&1
  }

  # Loop to wait until Docker is ready
  while ! is_docker_ready; do
    sleep 1
    elapsed=$((elapsed + 1))

    if [[ "$elapsed" -ge "$timeout" ]]; then
      echo "Error: Container '$container_name' did not become available within $timeout seconds."
      return 1
    fi
  done

  echo "Container '$container_name' is available. Proceeding..."
  return 0
}

# Example usage of the function
# Uncomment the lines below to test the function in a script:

# wait_for_docker "my_container" 30
# if [[ $? -eq 0 ]]; then
#   echo "Container is ready. Running further commands..."
# else
#   echo "Failed to connect to the container."
# fi
