#!/bin/bash

# Source operation functions
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
SERVICE_OPERATIONS_DIR="$SCRIPT_DIR/operations/service"
MESH_OPERATIONS_DIR="$SCRIPT_DIR/operations/mesh"
UTILS_DIR="$SCRIPT_DIR/utils"

source "$SERVICE_OPERATIONS_DIR/start.sh"
source "$SERVICE_OPERATIONS_DIR/restart.sh"
source "$SERVICE_OPERATIONS_DIR/stop.sh"
source "$SERVICE_OPERATIONS_DIR/clean.sh"
source "$SERVICE_OPERATIONS_DIR/exec.sh"
source "$SERVICE_OPERATIONS_DIR/logs.sh"
source "$SERVICE_OPERATIONS_DIR/ls.sh"
source "$SERVICE_OPERATIONS_DIR/up.sh"
source "$SERVICE_OPERATIONS_DIR/down.sh"
source "$MESH_OPERATIONS_DIR/up.sh"
source "$MESH_OPERATIONS_DIR/down.sh"
source "$UTILS_DIR"/wait_for_docker.sh
source "$UTILS_DIR"/docker_utils.sh

# Display usage information
usage() {
  cat <<EOF
NAME
    hyperservice - Manage hyperservices in the service mesh

DESCRIPTION
    This command-line tool manages hyperservices in the service mesh. 
    It allows you to start, restart, stop, clean, list, execute commands, or view logs for hyperservices.

OPTIONS
    --workdir <workdir>
        Specify the working directory inside the container.
        Required for 'start' and 'restart' actions.

    --recreate
        If specified with the 'start' action, the hyperservice will be recreated.

    --clean
        If specified with the 'down' action, the hyperservice will be cleaned.

    <name>
        Set the name of the hyperservice to manage.
        Required for all actions except 'ls'.

    <operation>
        Set the operation to be executed by hyperservice.
        The following operations are available:

          start
              hyperservice --workdir <workdir> [--recreate] <name> start
              Start the hyperservice, creating it if it doesn't exist.
              If --recreate is specified, the hyperservice will be recreated.

          stop
              hyperservice <name> stop
              Stop a running hyperservice.

          clean
              hyperservice <name> clean
              Remove the hyperservice completely.

          exec
              hyperservice <name> exec
              Open an interactive bash shell in the hyperservice container.

          logs
              hyperservice <name> logs
              View the logs of the specified hyperservice.

          ls
              hyperservice ls
              List all hyperservices with specific details.

          service up
              hyperservice up
              Start all hyperservices in the workspace.

          service up --recreate
              hyperservice --recreate up
              Recreate and start all hyperservices in the workspace.

          service down
              hyperservice down
              Stop all hyperservices in the workspace.

          service down --clean
              hyperservice --clean down
              Clean all hyperservices in the workspace.

          mesh up
              hyperservice mesh up
              Start the service mesh.

          mesh --services up
              hyperservice mesh --services up
              Start the service mesh and all hyperservices.

          mesh down
              hyperservice mesh down
              Stop the service mesh.

          mesh --services down
              hyperservice mesh --services down
              Stop the service mesh and all hyperservices.

USAGE EXAMPLES
    Start a hyperservice:
        hyperservice --workdir apps/service-a service-a start

    Start a hyperservice with recreation:
        hyperservice --workdir apps/service-a --recreate service-a start

    Stop a hyperservice:
        hyperservice service-a stop

    Clean a hyperservice:
        hyperservice service-a clean

    Open an interactive shell:
        hyperservice service-a exec

    View logs of a hyperservice:
        hyperservice service-a logs

    List all hyperservices:
        hyperservice ls

    Start all hyperservices:
        hyperservice service up

    Recreate and start all hyperservices:
        hyperservice service --recreate up

    Stop all hyperservices:
        hyperservice service down

    Clean all hyperservices:
        hyperservice service --clean down

    Start the service mesh:
        hyperservice mesh up

    Start the service mesh and all hyperservices:
        hyperservice mesh --services up

    Stop the service mesh:
        hyperservice mesh down

    Stop the service mesh and all hyperservices:
        hyperservice mesh --services down

EOF
  exit 1
}

# Parse parameters
WORKDIR=""
NAME=""
ACTION=""
RECREATE=""
CLEAN=""
MESH=""
SERVICES=""
SERVICE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --recreate) RECREATE="true"; shift ;;
    --clean) CLEAN="true"; shift ;;
    mesh) MESH="true"; shift ;;
    service) SERVICE="true"; shift ;;
    --services) SERVICES="true"; shift ;;
    start|stop|clean|exec|logs|ls|up|down) ACTION="$1"; shift ;;
    *) 
      if [[ -z "$NAME" ]]; then
        NAME="$1"
        shift
      else
        echo "Unknown parameter: $1"
        usage
      fi
      ;;
  esac
done

# Validate required parameters
if [[ -z "$NAME" && "$ACTION" != "ls" && "$ACTION" != "up" && "$ACTION" != "down" && "$ACTION" != "mesh" ]]; then
  echo "Error: <name> is required for all actions except 'ls', 'up', 'down', and 'mesh'."
  usage
fi

if [[ "$ACTION" == "start" || "$ACTION" == "restart" ]] && [[ -z "$WORKDIR" ]]; then
  echo "Error: --workdir is required for 'start' and 'restart' actions."
  usage
fi

if [[ "$ACTION" != "start" && "$RECREATE" == "true" && "$ACTION" != "up" ]]; then
  echo "Error: --recreate is only valid with the 'start' and 'up' actions."
  usage
fi

if [[ "$ACTION" != "down" && "$CLEAN" == "true" ]]; then
  echo "Error: --clean is only valid with the 'down' action."
  usage
fi

if [[ "$NAME" =~ \  ]]; then
  echo "Error: <name> cannot contain spaces."
  usage
fi

# Ensure WORKSPACE_FOLDER is set as an environment variable
if [[ -z "$WORKSPACE_FOLDER" && "$ACTION" != "ls" && "$ACTION" != "up" && "$ACTION" != "down" && "$ACTION" != "mesh" ]]; then
  echo "Error: WORKSPACE_FOLDER environment variable is not set."
  exit 1
fi

# Normalize WORKSPACE_FOLDER to remove trailing slash
WORKSPACE_FOLDER="${WORKSPACE_FOLDER%/}"

# Check if the hyperservice exists
hyperservice_exists() {
  docker_container_exists "$NAME"
}

if [[ "$MESH" == "true" ]]; then
# Handle mesh actions
case $ACTION in
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
    echo "Unknown action: $ACTION"
    usage
    ;;  
  esac
elif [[ "$SERVICE" == "true" ]]; then
# Handle mesh actions
case $ACTION in
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
  *)
    echo "Unknown action: $ACTION"
    usage
    ;;  
  esac
else
  # Handle service actions
  case $ACTION in
    start)
      if [[ "$RECREATE" == "true" ]]; then
        service_restart "$NAME" "$WORKDIR"
      else
        service_start "$NAME" "$WORKDIR"
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
    ls)
      service_ls
      ;;
    *)
      echo "Unknown action: $ACTION"
      usage
      ;;
  esac
fi
