# Function to handle fleet unit simulation
create_fleet_unit() {
  local service_name="$1"
  local workdir="$2"

  # Generate unique base name for the fleet unit
  local base_name="${service_name}-$(uuidgen | cut -c1-8)"
  local node_name="${base_name}-node"

  echo "Creating and starting fleet unit simulation: $node_name"
  run_service "$service_name" "$workdir" hyperservice-fleet-simulator-image "$node_name"

  echo "Accessing fleet unit simulation: $node_name"
  wait_for_docker "$node_name" 60
  docker exec "$node_name" echo "Container $node_name is ready for docker exec" || echo "Debug: docker exec failed for $node_name"
  if [[ $? -eq 0 ]]; then
    echo "Fleet unit is ready. Starting hyperservice: $base_name"
    docker exec "$node_name" \
      bash -c "cd $HYPERSERVICE_WORKSPACE_PATH && bash modules/hyperservice/install.sh && hyperservice --workdir=\"$workdir\" --node=\"$base_name\" \"$service_name\" start"

  else
    echo "Failed to connect to fleet unit: $node_name"
  fi
}