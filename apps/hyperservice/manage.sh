#!/bin/bash

# Display usage information
usage() {
  cat <<EOF
NAME
    hyperservice - Manage hyperservices using Docker

SYNOPSIS
    hyperservice --workdir <workdir> --name <name> <action>

DESCRIPTION
    This script is a command-line tool to manage hyperservices using Docker. 
    It allows you to start, restart, stop, or clean hyperservices.

OPTIONS
    --workdir <workdir>   Specify the working directory inside the container.
    --name <name>         Set the name of the hyperservice to manage.
    <action>              The action to perform on the hyperservice.
                          Available actions:
                            - start    Start the hyperservice, creating it if it doesn't exist.
                            - restart  Remove the hyperservice (if exists) and create a new one.
                            - stop     Stop a running hyperservice.
                            - clean    Remove the hyperservice completely.

USAGE EXAMPLES
    Start a hyperservice:
        hyperservice --workdir /workspace/apps/node-service-a --name service-a start

    Restart a hyperservice:
        hyperservice --workdir /workspace/apps/node-service-a --name service-a restart

EOF
  exit 1
}

# Parse parameters
WORKDIR=""
NAME=""
ACTION=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    start|restart|stop|clean) ACTION="$1"; shift ;;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
done

# Validate required parameters
if [[ -z "$NAME" || -z "$ACTION" ]]; then
  echo "Error: --name and an action are required."
  usage
fi

if [[ "$ACTION" == "start" || "$ACTION" == "restart" ]] && [[ -z "$WORKDIR" ]]; then
  echo "Error: --workdir is required for 'start' and 'restart' actions."
  usage
fi

# Ensure LOCAL_WORKSPACE_FOLDER is set as an environment variable
if [[ -z "$LOCAL_WORKSPACE_FOLDER" ]]; then
  echo "Error: LOCAL_WORKSPACE_FOLDER environment variable is not set."
  exit 1
fi

# Normalize LOCAL_WORKSPACE_FOLDER to remove trailing slash
LOCAL_WORKSPACE_FOLDER="${LOCAL_WORKSPACE_FOLDER%/}"

# Check if the hyperservice exists
hyperservice_exists() {
  docker ps -a --format "{{.Names}}" | grep -qw "$NAME"
}

if [[ "$ACTION" == "start" || "$ACTION" == "restart" ]] && [[ ! -d "$WORKDIR" ]]; then
  echo "Error: The directory '$WORKDIR' does not exist in the mounted LOCAL_WORKSPACE_FOLDER."
  echo "Ensure that the directory exists on the host and matches the expected structure."
  exit 1
fi

# Handle actions
case $ACTION in
  start)
    if hyperservice_exists; then
      echo "Starting existing hyperservice: $NAME"
      docker start "$NAME"
    else
      echo "Creating and starting hyperservice: $NAME"
      docker run -d \
        --name "$NAME" \
        --volume "${LOCAL_WORKSPACE_FOLDER}:/workspace" \
        --volume "/etc/environment:/etc/environment:ro" \
        --workdir "$WORKDIR" \
        --env-file "/etc/environment" \
        --env "KUMA_DPP=$NAME" \
        --env "DATA_PLANE_NAME=$NAME" \
        --env "CONTROL_PLANE_NAME=control-plane" \
        --network service-mesh \
        --privileged \
        hyper-dataplane-image
    fi
    ;;
  restart)
    if hyperservice_exists; then
      echo "Removing existing hyperservice: $NAME"
      docker rm -f "$NAME"
    fi
    echo "Creating and starting hyperservice: $NAME"
    docker run -d \
      --name "$NAME" \
      --volume "${LOCAL_WORKSPACE_FOLDER}:/workspace" \
      --volume "/etc/environment:/etc/environment:ro" \
      --workdir "$WORKDIR" \
      --env-file "/etc/environment" \
      --env "KUMA_DPP=$NAME" \
      --env "DATA_PLANE_NAME=$NAME" \
      --env "CONTROL_PLANE_NAME=control-plane" \
      --network service-mesh \
      --privileged \
      hyper-dataplane-image
    ;;
  stop)
    if hyperservice_exists; then
      echo "Stopping hyperservice: $NAME"
      docker stop "$NAME"
    else
      echo "Error: Hyperservice '$NAME' does not exist."
      exit 1
    fi
    ;;
  clean)
    if hyperservice_exists; then
      echo "Removing hyperservice: $NAME"
      docker rm -f "$NAME"
    else
      echo "Error: Hyperservice '$NAME' does not exist."
      exit 1
    fi
    ;;
  *)
    echo "Unknown action: $ACTION"
    usage
    ;;
esac
