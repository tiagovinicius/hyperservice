# Main function to start hyperservice
service_start() {
  local service_name="$1"
  local workdir="$2"
  local service_only="$3"
  local node_name="$4"

  # Get the Deployment name that matches the label
  local deployment=$(kubectl get deployments -n "$HYPERSERVICE_NAMESPACE" -l "app=$service_name" -o jsonpath="{.items[*].metadata.name}")

  # Continue only if a deployment is found
  if [ -n "$deployment" ]; then
      echo "🔄 Recreating hyperservice: $service_name"

      # Delete the deployment
      echo "🗑️ Deleting hyperservice..."
      kubectl delete deployment "$deployment" -n "$HYPERSERVICE_NAMESPACE"

      echo "✅ hyperservice '$service_name' successfully deleted!"
  else
      echo "⚠️ No hyperservice found with name $service_name in namespace $HYPERSERVICE_NAMESPACE"
  fi

  echo "Starting hyperservice: $service_name"

  workdir=$(resolve_workdir "$service_name" "$workdir")
  if [[ $? -ne 0 ]]; then
    echo "$workdir"
    return 1
  fi

  simulation_units_count=$(yq -r '.simulator.units // 0' "$workdir/.hyperservice/fleet.yml" 2>/dev/null || echo 0)
  remote_units_count=$(yq -r '.units // [] | .[] | "\(.host) \(.port // "22") \(.username // "root") \(.["key-file"] // "")"' "$workdir/.hyperservice/fleet.yml" 2>/dev/null | wc -l)


  # if [[ -z "$node_name" && ( "$service_only" == "0" || "$service_only" == "false" ) ]]; then
  #     # Create fleet units if applicable
  #     for ((i = 1; i <= simulation_units_count; i++)); do
  #       create_fleet_unit "$service_name" "$workdir"
  #     done
  # fi

  if [[ "$service_only" == "0" || "$service_only" == "false" ]]; then
    yq -r '.units // [] | .[] | "\(.host) \(.port // "22") \(.username // "root") \(.["key-file"])"' "$workdir/.hyperservice/fleet.yml" 2>/dev/null | while IFS=' ' read -r ip port username key_file; do
      echo "Setting up fleet unit with IP: $ip, Port: $port, Username: $username, Key File: $key_file"
      deploy_fleet_unit "$service_name" "$workdir" "$ip" "$port" "$username" "$key_file"
    done || echo "No remote fleet units to set up or fleet.yml not found."
  fi

  # Start the main hyperservice if no fleet units were created
  if [[ "$service_only" == "true" || "$service_only" == "1" || ($simulation_units_count -eq 0 && remote_units_count -eq 0) ]]; then
    run_service "$service_name" "$workdir" hyperservice-dataplane-image "$node_name"
  fi

  echo "Hyperservice $service_name started successfully."
}
