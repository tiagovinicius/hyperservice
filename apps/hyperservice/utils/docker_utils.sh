#!/bin/bash

# Function to check if a Docker container exists
docker_container_exists() {
  local container_name="$1"
  docker ps -a --format "{{.Names}}" | grep -E -qw "^$container_name(-.*|$)"
}

# Function to start a Docker container
docker_container_start() {
  local container_name="$1"
  docker start "$container_name"
}

# Function to stop a Docker container
docker_container_stop() {
  local container_name="$1"
  docker stop "$container_name"
}

# Function to remove a Docker container
docker_container_remove() {
  local container_name="$1"
  docker rm "$container_name"
}

# Function to run a Docker container
docker_container_run() {
  local container_name="$1"
  shift
  docker run --name "$container_name" "$@"
}

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

# Function to iterate through containers with name pattern name=^$name(-.*|$)
iterate_containers() {
  local name="$1"
  docker ps -a --filter "name=^$name(-.*|$)" --format "{{.Names}}"
}
