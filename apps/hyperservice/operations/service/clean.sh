# Function to clean hyperservice

service_clean() {
  local name="$1"

  echo "Cleaning hyperservice: $name"

  # Check if the hyperservice exists
  if ! hyperservice_exists "$name"; then
    echo "Hyperservice $name does not exist."
    return
  fi

  # Stop the hyperservice if it is running
  if docker ps -q --filter "name=$name" | grep -q .; then
    echo "Stopping hyperservice: $name"
    docker stop "$name"
  fi
  
  # Remove the hyperservice
  docker rm "$name"

  echo "Hyperservice $name cleaned successfully."
}
