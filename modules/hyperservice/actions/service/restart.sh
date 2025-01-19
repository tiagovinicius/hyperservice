# Function to restart hyperservice

service_restart() {
  local name="$1"
  local workdir="$2"
  local node_name="$3"

  echo "Restarting hyperservice: $name"

  if docker_container_exists; then
    echo "Removing existing hyperservice: $NAME"
    docker_container_remove "$NAME"
  fi

  # Read units or default to 0
  local units
  units=$(yq -r '.simulator.units // 0' "$workdir/.hyperservice/fleet.yml" 2>/dev/null || echo 0)

  if [[ -z "$node_name" ]]; then
    # Create fleet units if applicable
    for ((i = 1; i <= units; i++)); do
      create_fleet_unit "$service_name" "$workdir"
    done
  fi

  # Start the main hyperservice if no fleet units were created
  if [[ $units -eq 0 ]]; then
    if docker_container_exists "$service_name"; then
      echo "Starting existing hyperservice: $service_name"
    else
      echo "Creating and starting new hyperservice: $service_name"
    fi
      run_service "$service_name" "$workdir" hyperservice-dataplane-image "$node_name"
  fi

  echo "Hyperservice $name restarted successfully."
}
