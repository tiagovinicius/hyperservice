# Function to exec hyperservice

service_exec() {
  local name="$1"

  echo "Executing hyperservice: $name"

  # Check if the hyperservice exists
  if ! hyperservice_exists "$name"; then
    echo "Hyperservice $name does not exist."
    return
  fi

  # Execute the hyperservice
  docker exec -it "$name" /bin/bash

  echo "Hyperservice $name executed successfully."
}
