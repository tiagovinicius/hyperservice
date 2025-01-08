# Function to handle the 'up' command
service_up() {
  local recreate="$1"
  local json_output
  json_output=$(moon query projects --json)

  echo "$json_output" | jq -c '.projects[]' | while read -r project; do
    local name
    local workdir
    name=$(echo "$project" | jq -r '.id')
    workdir=$(echo "$project" | jq -r '.source')

    if [[ -f "$workdir/.hyperservice/dataplane.yml" ]]; then
      if [[ "$recreate" == "true" ]]; then
        hyperservice --workdir "$workdir" --recreate "$name" start
      else
        hyperservice --workdir "$workdir" "$name" start
      fi
    fi
  done
}