#!/bin/bash

service_dispatch() {
  local action="$1"
  local name="$2"
  local workdir="$3"

  case $action in
    start)
      if [[ "$RECREATE" == "true" ]]; then
        service_restart "$NAME" "$WORKDIR" "$NODE_NAME"
      else
        service_start "$NAME" "$WORKDIR" "$NODE_NAME"
      fi
      ;;
    stop)
      service_stop "$NAME"
      ;;
    clean)
      service_clean "$NAME"
      ;;
    exec)
      service_exec "$NAME"
      ;;
    logs)
      service_logs "$NAME"
      ;;
    up)
      service_up "$RECREATE"
      ;;
    down)
      if [[ "$CLEAN" == "true" ]]; then
        service_down_clean
      else
        service_down
      fi
      ;;
    ls)
      service_ls
      ;;
    *)
      echo "Error: Unsupported action '$action' for service."
      exit 1
      ;;
  esac
}
