# Function to handle the 'down' command
service_down() {
  local json_output
  json_output=$(moon query projects --json)

  echo "$json_output" | jq -c '.projects[]' | while read -r project; do
    local name
    local workdir
    name=$(echo "$project" | jq -r '.id')
    workdir=$(echo "$project" | jq -r '.source')

    if [[ -f "$workdir/.hyperservice/dataplane.yml" ]]; then
      docker_container_stop "$name"
    fi
  done
}

# Function to handle the 'down --clean' command
service_down_clean() {
  local json_output
  json_output=$(moon query projects --json)

  echo "$json_output" | jq -c '.projects[]' | while read -r project; do
    local name
    local workdir
    name=$(echo "$project" | jq -r '.id')
    workdir=$(echo "$project" | jq -r '.source')

    if [[ -f "$workdir/.hyperservice/dataplane.yml" ]]; then
      docker_container_stop "$name"
      docker_container_remove "$name"
    fi
  done
}
