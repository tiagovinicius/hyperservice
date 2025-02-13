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

  HYPERSERVICE_IMAGE="$image" \
  SERVICE_NAME="$service_name" \
  HYPERSERVICE_BIN_PATH="$HYPERSERVICE_BIN_PATH" \
  HYPERSERVICE_WORKSPACE_PATH="$HYPERSERVICE_WORKSPACE_PATH" \
  HYPERSERVICE_SHARED_ENVIRONMENT="$HYPERSERVICE_SHARED_ENVIRONMENT" \
  HYPERSERVICE_APP_PATH="$workdir" \
  HYPERSERVICE_DATAPLANE_NAME="$node_name" \
  K8S_NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')" \
  envsubst <"$HYPERSERVICE_BIN_PATH/actions/service/start.yaml" | kubectl apply -f -
  kubectl rollout restart deployment "$node_name" -n kuma-system
}

wait_for_control_plane() {
  echo "⏳ Waiting for Kuma Control Plane to be ready..."
  while true; do
      STATUS=$(kubectl get pod -n kuma-system -l app=kuma-control-plane -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
      if [[ "$STATUS" == "Running" ]]; then
          echo "✅ Kuma Control Plane is ready!"
          break
      fi
      echo "🔄 Kuma Control Plane is not ready (status: $STATUS), retrying in 5s..."
      sleep 5
  done
}
