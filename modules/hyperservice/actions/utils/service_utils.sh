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

  bash modules/hyperservice/mesh/dataplane/build-image.sh

  docker_container_run "$node_name" \
    --volume "/var/run/docker.sock:/var/run/docker.sock" \
    --volume "$HYPERSERVICE_BIN_PATH:$HYPERSERVICE_BIN_PATH" \
    --volume "$HYPERSERVICE_WORKSPACE_PATH:$HYPERSERVICE_WORKSPACE_PATH" \
    --volume "$HYPERSERVICE_SHARED_ENVIRONMENT:$HYPERSERVICE_SHARED_ENVIRONMENT" \
    --workdir "$HYPERSERVICE_WORKSPACE_PATH" \
    --env "KUMA_DPP=$node_name" \
    --env "DATAPLANE_NAME=$node_name" \
    --env "SERVICE_NAME=$service_name" \
    --env "HYPERSERVICE_BIN_PATH=$HYPERSERVICE_BIN_PATH" \
    --env "HYPERSERVICE_APP_PATH=$workdir" \
    --network service-mesh \
    --privileged \
    "$image" \
    "${additional_args[@]}" &
}

wait_for_control_plane() {
  echo "Waiting control plane to be running"
  elapsed=0
  sleep_interval=1
  check_kuma_status() {
    echo "Accessing control plane..."
    CONTROL_PLANE_IP=$(cat $HYPERSERVICE_SHARED_ENVIRONMENT/CONTROL_PLANE_IP 2>/dev/null || true)
    CONTROL_PLANE_ADMIN_USER_TOKEN=$(cat $HYPERSERVICE_SHARED_ENVIRONMENT/CONTROL_PLANE_ADMIN_USER_TOKEN 2>/dev/null || true)
    echo "XXXXXXXXXXXXXXXXXX $HYPERSERVICE_SHARED_ENVIRONMENT $CONTROL_PLANE_IP $CONTROL_PLANE_IP"
    temp_file=$(mktemp)
    kumactl config control-planes add \
      --name=default \
      --address=http://$CONTROL_PLANE_IP:5681 \
      --auth-type=tokens \
      --auth-conf token=${CONTROL_PLANE_ADMIN_USER_TOKEN} 2>&1 >"$temp_file"
    [ $? -ne 0 ] || grep -Eq "could not connect" "$temp_file" && {
      echo "Error executing kumactl"
      cat "$temp_file"
      rm "$temp_file"
      return 1
    }
    echo "Kumactl executed successfully"
    rm "$temp_file"
  }
  while ! check_kuma_status; do
    echo "Waiting for control plane to be running..."
    sleep $sleep_interval
    elapsed=$((elapsed + sleep_interval))

    if [ $sleep_interval -lt 60 ]; then
      sleep_interval=$((sleep_interval * 2))
      if [ $sleep_interval -gt 60 ]; then
        sleep_interval=60
      fi
    fi
  done
  echo "Control plane is running"
}
