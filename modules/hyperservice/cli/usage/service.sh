#!/bin/bash

service_usage() {
  cat <<EOF
NAME
    hyperservice service

start
    hyperservice --workdir=<workdir> [--recreate] <name> start
    Start the hyperservice, creating it if it doesn't exist.
    If --recreate is specified, the hyperservice will be removed, recreated and started.

    OPTIONS
        --workdir=<workdir>
        Specify the working directory inside the container.
        Required for 'start' and 'restart' actions.

        --recreate
            If specified with the 'start' action, the hyperservice will be removed, recreated and started.

        <name>
            Set the name of the hyperservice to manage.

    USAGE EXAMPLES
        Start a hyperservice:
            hyperservice --workdir=apps/service-a service-a start

        Start a hyperservice with recreation:
            hyperservice --workdir=apps/service-a --recreate service-a start


stop
    hyperservice <name> stop
    Stop a running hyperservice.

    OPTIONS
        <name>
            Set the name of the hyperservice to manage.

    USAGE EXAMPLES
        Stop a hyperservice:
            hyperservice service-a stop


clean
    hyperservice <name> clean
    Remove the hyperservice completely.

    OPTIONS
        <name>
            Set the name of the hyperservice to manage.

    USAGE EXAMPLES
        Clean a hyperservice:
            hyperservice service-a clean


exec
    hyperservice <name> exec
    Open an interactive bash shell in the hyperservice container.

    OPTIONS
        <name>
            Set the name of the hyperservice to manage.

    USAGE EXAMPLES
        Open an interactive shell:
            hyperservice service-a exec


logs
    hyperservice <name> logs
    View the logs of the specified hyperservice.

    OPTIONS
        <name>
            Set the name of the hyperservice to manage.

    USAGE EXAMPLES
        View logs of a hyperservice:
            hyperservice service-a logs

ls
    hyperservice ls
    List all hyperservices with specific details.

    USAGE EXAMPLES
        List all hyperservices:
            hyperservice ls


service up
    hyperservice service [--recreate] up
    Start all hyperservices in the workspace.
    If --recreate is specified, the hyperservice will be removed, recreated and started.

    OPTIONS
        --recreate
            If specified with the 'up' action, the hyperservice will be removed, recreated and started.

    USAGE EXAMPLES
        Start all hyperservices:
            hyperservice service up

        Recreate and start all hyperservices:
            hyperservice service --recreate up


service down
    hyperservice [--clean] down
    Stop all hyperservices in the workspace.
    If --clean is specified, the hyperservice will be stopped and removed.

    OPTIONS
        --clean
            If specified with the 'down' action, the hyperservice will be stopped and removed.
    
    USAGE EXAMPLES
        Stop all hyperservices:
            hyperservice service down

        Clean all hyperservices:
            hyperservice service --clean down

EOF
  exit 0
}
