#!/bin/bash

mesh_dispatch() {
  local action="$1"
  local services="$2"
  
  case $action in
    up)
      mesh_up &
      mesh_up_pid=$!
      if [[ "$SERVICES" == "true" ]]; then
        service_up "$RECREATE" &
      fi
      wait $mesh_up_pid
      ;;
    down)
      if [[ "$CLEAN" == "true" ]]; then
        service_down_clean
      else
        service_down
      fi
      mesh_down
      ;;
    *)
      echo "Error: Unsupported action '$action' for mesh."
      exit 1
      ;;
  esac
}
