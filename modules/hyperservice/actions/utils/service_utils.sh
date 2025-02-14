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

  wait_for_control_plane_readiness

  HYPERSERVICE_IMAGE="$image" \
  SERVICE_NAME="$service_name" \
  HYPERSERVICE_BIN_PATH="$HYPERSERVICE_BIN_PATH" \
  HYPERSERVICE_WORKSPACE_PATH="$HYPERSERVICE_WORKSPACE_PATH" \
  HYPERSERVICE_SHARED_ENVIRONMENT="$HYPERSERVICE_SHARED_ENVIRONMENT" \
  HYPERSERVICE_NAMESPACE="$HYPERSERVICE_NAMESPACE" \
  HYPERSERVICE_APP_PATH="$workdir" \
  HYPERSERVICE_DATAPLANE_NAME="$node_name" \
  K8S_NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')" \
  envsubst <"$HYPERSERVICE_BIN_PATH/actions/service/start.yaml" | kubectl apply -f -

  echo "Applying policies..."
  # Define the POLICIES_DIR path
  POLICIES_DIR="$HYPERSERVICE_CURRENT_WORKSPACE_PATH/$workdir/.hyperservice/policies"

  # Check if the directory exists before listing files
  if [ -d "$POLICIES_DIR" ]; then
      # Get all .yml files in the directory
      YAML_FILES=$(find "$POLICIES_DIR" -maxdepth 1 -type f -name "*.yml" | sort)

      # Check if there are YAML files before iterating
      if [ -n "$YAML_FILES" ]; then
          for FILE in $YAML_FILES; do
              echo "📄 Applying file: $FILE"
              echo "$(envsubst <"$FILE")" | kubectl apply -f -
          done
      else
          echo "⚠️ No policy files found in $POLICIES_DIR"
      fi
  else
      echo "⚠️ A policies directory does not exist: $POLICIES_DIR"
  fi
}

wait_for_control_plane_liveness() {
  echo "⏳ Waiting for Kuma Control Plane pod to be in Running state..."
  until kubectl get pods -n kuma-system -l app=kuma-control-plane -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; do
      echo "🔄 Kuma Control Plane pod is not ready yet. Retrying in 5s..."
      sleep 5
  done

  echo "✅ Kuma Control Plane pod is now Running!"

  echo "⏳ Waiting for Kuma Control Plane service to have active endpoints..."
  until kubectl get endpoints -n kuma-system kuma-control-plane -o jsonpath="{.subsets}" | grep -q "addresses"; do
      echo "🔄 Kuma Control Plane service does not have active endpoints yet. Retrying in 5s..."
      sleep 5
  done

  echo "✅ Kuma Control Plane service is now ready!"
}

wait_for_control_plane_readiness () {
  # Wait for the Kuma Control Plane to be responsive on port 5681
  until curl -s "http://localhost:5681" >/dev/null; do
      echo "🔄 Waiting for Kuma Control Plane (http://locahost:5681) to respond..."
      sleep 5
  done
}