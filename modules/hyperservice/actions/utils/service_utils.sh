resolve_workdir() {
  local service_name="$1"
  local workdir="$2"

  if [[ -z "$workdir" ]]; then
    local json_output
    json_output=$(moon query projects --json)
    workdir=$(echo "$json_output" | jq -r --arg service_name "$service_name" '.projects[] | select(.id == $service_name) | .source')
  fi

  if [[ -z "$workdir" ]]; then
    echo "Error: Unable to determine workdir for service: $service_name"
    return 1
  fi

  echo "$workdir"
}

run_service() {
  local service_name="$1"
  local workdir="$2"
  local image="$3"
  local node_name="${4:-$service_name}" # Default to service_name if node_name is not provided
  shift 4
  local additional_args=("$@")

  echo "Running Docker container: $node_name"
  docker_container_run "$node_name" \
    --volume "/var/run/docker.sock:/var/run/docker.sock" \
    --volume "$HYPERSERVICE_DEV_HOST_WORKSPACE_PATH:/workspace" \
    --volume "/etc/shared/environment:/etc/shared/environment" \
    --workdir "/workspace/$workdir" \
    --env "KUMA_DPP=$node_name" \
    --env "DATAPLANE_NAME=$node_name" \
    --env "SERVICE_NAME=$service_name" \
    --env "HYPERSERVICE_DEV_HOST_WORKSPACE_PATH=$HYPERSERVICE_DEV_HOST_WORKSPACE_PATH" \
    --network service-mesh \
    --privileged \
    "$image" \
    "${additional_args[@]}" &
}
