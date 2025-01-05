# Function to view logs of hyperservice

service_logs() {
  local name="$1"

  echo "Viewing logs for hyperservice: $name"

  # Check if the hyperservice exists
  if ! hyperservice_exists "$name"; then
    echo "Hyperservice $name does not exist."
    return
  fi

  # View the logs of the hyperservice
  docker logs "$name"
}
