#!/bin/bash

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

    <name>
        Set the name of the hyperservice to manage.
        Required for all actions except 'ls'.

    <operation>
        Set the operation to be executed by hyperservice.
        The following operations are available:

          start
              hyperservice --workdir <workdir> <name> start
              Start the hyperservice, creating it if it doesn't exist.

          restart
              hyperservice --workdir <workdir> <name> restart
              Remove the hyperservice (if exists) and create a new one.

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
        hyperservice --workdir apps/node-service-a service-a start

    Restart a hyperservice:
        hyperservice --workdir apps/node-service-a service-a restart

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

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --workdir) WORKDIR="$2"; shift 2 ;;
    start|restart|stop|clean|exec|logs|ls) ACTION="$1"; shift ;;
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

echo "Workdir is /workspace/$WORKDIR" 

# Check if the hyperservice exists
hyperservice_exists() {
  docker ps -a --format "{{.Names}}" | grep -qw "$NAME"
}

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
        --workdir "/workspace/$WORKDIR" \
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
      --workdir "/workspace/$WORKDIR" \
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
  exec)
    if hyperservice_exists; then
      echo "Opening bash shell in hyperservice: $NAME"
      docker exec -it "$NAME" /bin/bash
    else
      echo "Error: Hyperservice '$NAME' does not exist."
      exit 1
    fi
    ;;
  logs)
    if hyperservice_exists; then
      echo "Displaying logs for hyperservice: $NAME"
      docker logs "$NAME"
    else
      echo "Error: Hyperservice '$NAME' does not exist."
      exit 1
    fi
    ;;
  ls)
    echo "Listing all containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Ports}}"
    ;;
  *)
    echo "Unknown action: $ACTION"
    usage
    ;;
esac
