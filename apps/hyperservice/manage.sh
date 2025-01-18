#!/bin/bash

# Source operation functions
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
SERVICE_OPERATIONS_DIR="$SCRIPT_DIR/operations/service"
MESH_OPERATIONS_DIR="$SCRIPT_DIR/operations/mesh"
UTILS_DIR="$SCRIPT_DIR/utils"
MANAGE_DIR="$SCRIPT_DIR/manage"
FLEET_SIMULATOR_DIR="$SCRIPT_DIR/fleet-simulator"

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
source "$UTILS_DIR"/service_utils.sh
source "$UTILS_DIR"/docker_utils.sh
source "$MANAGE_DIR/modules/helpers.sh"
source "$MANAGE_DIR/modules/rules.sh"
source "$MANAGE_DIR/modules/arguments.sh"
source "$MANAGE_DIR/modules/dispatch.sh"
source "$MANAGE_DIR/usage/default.sh"
source "$MANAGE_DIR/usage/service.sh"
source "$MANAGE_DIR/usage/mesh.sh"
source "$MANAGE_DIR/usage/interactive.sh"
source "$MANAGE_DIR/actions/mesh.sh"
source "$MANAGE_DIR/actions/service.sh"
source "$FLEET_SIMULATOR_DIR/create_fleet_unit.sh"

# Parse arguments
parse_arguments "$@"

# Se nenhum input for informado, execute a função `interactive`
if [[ -z "$ENTITY" && -z "$ACTION" && -z "$NAME" && -z "${PARAMS[*]}" ]]; then
  interactive
  return
fi

# Validate input
validate_input validate_workdir_rule

# Dispatch the action
dispatch_action
