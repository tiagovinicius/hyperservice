#!/bin/bash

# Function to check if a Docker container exists
docker_container_exists() {
  local container_name="$1"
  docker ps -a --format "{{.Names}}" | grep -E -qw "^$container_name(-.*|$)"
}

# Function to start a Docker container
docker_container_start() {
  local container_name="$1"
  for container in $(iterate_containers $container_name); do
    docker start "$container" &
  done
}

# Function to stop a Docker container
docker_container_stop() {
  local container_name="$1"
  for container in $(iterate_containers $container_name); do
  echo "$container"
    docker stop "$container"
  done
}

# Function to remove a Docker container
docker_container_remove() {
  local container_name="$1"
  for container in $(iterate_containers $container_name); do
    docker rm "$container"
  done
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
  for container in $(iterate_containers $container_name); do
    # Ensure a container name is provided
    if [[ -z "$container" ]]; then
      echo "Error: Container name is required."
      echo "Usage: wait_for_docker <container_name> [timeout]"
      return 1
    fi

    echo "Waiting for container '$container' to become available..."

    local elapsed=0

    # Function to check if Docker is ready
    is_docker_ready() {
      if docker_container_exists "$container_name"; then
      echo "container_name $container_name"
        docker exec "$container" echo "ready" >/dev/null 2>&1
       return $? # Return the status of the docker exec command
      else
        return 1 # Container does not exist
      fi
    }

    # Loop to wait until Docker is ready
    while ! is_docker_ready; do
      sleep 1
      elapsed=$((elapsed + 1))

      if [[ "$elapsed" -ge "$timeout" ]]; then
        echo "Error: Container '$container' did not become available within $timeout seconds."
        return 1
      fi
    done

    echo "Container '$container' is available. Proceeding..."
    return 0
  done
}

# Function to iterate through containers with name pattern name=^$name(-.*|$)
iterate_containers() {
  local name="$1"
  docker ps -a --filter "name=^$name(-.*|$)" --format "{{.Names}}"
}
