#!/bin/bash

default_usage() {
  cat <<EOF
NAME
    hyperservice 

DESCRIPTION
    This command-line tool manages services in the service mesh. 
    It allows you to start, restart, stop, clean, list, execute commands, or view logs for hyperservices.

USAGE
    hyperservice [entity] [parameters...] [name] <action>

ENTITIES
    mesh         Operations on the service mesh (run 'hyperservice mesh --help')
    service      Operations on individual services (default, run 'hyperservice service --help')

For more details, use '--help' with the specific entity.
EOF
  exit 0
}

