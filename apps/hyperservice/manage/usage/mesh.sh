#!/bin/bash

mesh_usage() {
  cat <<EOF
NAME
    hyperservice mesh

mesh up
    hyperservice mesh [--services] up
    Start the service mesh.
    If --services is specified, the service mesh and all services will be started.

    OPTIONS
        --services
            If specified with the 'up' action, the service mesh and all services will be started.

    USAGE EXAMPLES
        Start the service mesh:
            hyperservice mesh up

        Start the service mesh and all services:
            hyperservice mesh --services up


mesh down
    hyperservice down
    Stop the service mesh and all services in the workspace.

    USAGE EXAMPLES
        Stop the service mesh and all services:
            hyperservice mesh down

EOF
  exit 0
}
