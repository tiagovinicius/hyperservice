#!/bin/bash

# Source operation functions
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
SERVICE_OPERATIONS_DIR="$SCRIPT_DIR/operations/service"

source "$SERVICE_OPERATIONS_DIR/start.sh"
source "$SERVICE_OPERATIONS_DIR/restart.sh"
source "$SERVICE_OPERATIONS_DIR/stop.sh"
source "$SERVICE_OPERATIONS_DIR/clean.sh"
source "$SERVICE_OPERATIONS_DIR/exec.sh"
source "$SERVICE_OPERATIONS_DIR/logs.sh"
source "$SERVICE_OPERATIONS_DIR/ls.sh"

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

USAGE EXAMPLES
    Start a hyperservice:
        hyperservice --workdir apps/service-a service-a start

    Start a hyperservice with recreation:
        hyperservice --workdir apps/service-a --recreate service-a start

    Restart a hyperservice:
        hyperservice --workdir apps/service-a service-a restart

    Stop a hyperservice:
        hyperservice service-a stop

    Clean a hyperservice:
        hyperservice service-a clean

    Open an interactive shell:
        hyperservice service-a exec

    View logs of a hyperservice:
        hyperservice service-a logs

    List all containers:
        hyperservice ls

EOF
  exit 1
}

# Parse parameters
WORKDIR=""
NAME=""
ACTION=""
RECREATE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --recreate) RECREATE="true"; shift ;;
    start|stop|clean|exec|logs|ls) ACTION="$1"; shift ;;
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
if [[ -z "$NAME" && "$ACTION" != "ls" ]]; then
  echo "Error: <name> is required for all actions except 'ls'."
  usage
fi

if [[ "$ACTION" == "start" || "$ACTION" == "restart" ]] && [[ -z "$WORKDIR" ]]; then
  echo "Error: --workdir is required for 'start' and 'restart' actions."
  usage
fi

if [[ "$ACTION" != "start" && "$RECREATE" == "true" ]]; then
  echo "Error: --recreate is only valid with the 'start' action."
  usage
fi

if [[ "$NAME" =~ \  ]]; then
  echo "Error: <name> cannot contain spaces."
  usage
fi

# Ensure LOCAL_WORKSPACE_FOLDER is set as an environment variable
if [[ -z "$LOCAL_WORKSPACE_FOLDER" && "$ACTION" != "ls" ]]; then
  echo "Error: LOCAL_WORKSPACE_FOLDER environment variable is not set."
  exit 1
fi

# Normalize LOCAL_WORKSPACE_FOLDER to remove trailing slash
LOCAL_WORKSPACE_FOLDER="${LOCAL_WORKSPACE_FOLDER%/}"

# Check if the hyperservice exists
hyperservice_exists() {
  docker ps -a --format "{{.Names}}" | grep -qw "$NAME"
}

# Handle actions
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
