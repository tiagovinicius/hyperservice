#!/bin/bash
# Set HYPERSERVICE_WORKSPACE_PATH to the current script's execution directory
export HYPERSERVICE_WORKSPACE_PATH=$(pwd)
export HYPERSERVICE_DEV_HOST_WORKSPACE_PATH="${HYPERSERVICE_DEV_HOST_WORKSPACE_PATH:-$HYPERSERVICE_WORKSPACE_PATH}"
export HYPERSERVICE_BIN_PATH="/usr/local/bin/hyperservice-bin"
export HYPERSERVICE_REAL_BIN_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HYPERSERVICE_APPS_PATH="/etc/hyperservice"

# Define the required file paths
HYPERSERVICE_POLICY=".hyperservice/policies/mesh.yml"
MOON_WORKSPACE=".moon/workspace.yml"

# Check if the required files exist in the current directory
if [[ ! -f "$HYPERSERVICE_WORKSPACE_PATH/$HYPERSERVICE_POLICY" || ! -f "$HYPERSERVICE_WORKSPACE_PATH/$MOON_WORKSPACE" ]]; then
    echo "Error: The current path ($HYPERSERVICE_WORKSPACE_PATH) is not a valid hyperservice workspace."
    exit 1
fi

# Source operation functions
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
SERVICE_ACTIONS_DIR="$SCRIPT_DIR/actions/service"
MESH_ACTIONS_DIR="$SCRIPT_DIR/actions/mesh"
UTILS_DIR="$SCRIPT_DIR/actions/utils"
CLI_DIR="$SCRIPT_DIR/cli"
FLEET_SIMULATOR_DIR="$SCRIPT_DIR/fleet"

source "$SERVICE_ACTIONS_DIR/start.sh"
source "$SERVICE_ACTIONS_DIR/restart.sh"
source "$SERVICE_ACTIONS_DIR/stop.sh"
source "$SERVICE_ACTIONS_DIR/clean.sh"
source "$SERVICE_ACTIONS_DIR/exec.sh"
source "$SERVICE_ACTIONS_DIR/logs.sh"
source "$SERVICE_ACTIONS_DIR/ls.sh"
source "$SERVICE_ACTIONS_DIR/up.sh"
source "$SERVICE_ACTIONS_DIR/down.sh"
source "$MESH_ACTIONS_DIR/up.sh"
source "$MESH_ACTIONS_DIR/down.sh"
source "$UTILS_DIR"/service_utils.sh
source "$UTILS_DIR"/docker_utils.sh
source "$CLI_DIR/modules/helpers.sh"
source "$CLI_DIR/modules/rules.sh"
source "$CLI_DIR/modules/arguments.sh"
source "$CLI_DIR/modules/dispatch.sh"
source "$CLI_DIR/usage/default.sh"
source "$CLI_DIR/usage/service.sh"
source "$CLI_DIR/usage/mesh.sh"
source "$CLI_DIR/usage/interactive.sh"
source "$CLI_DIR/actions/mesh.sh"
source "$CLI_DIR/actions/service.sh"
source "$FLEET_SIMULATOR_DIR/create-fleet-unit.sh"
source "$FLEET_SIMULATOR_DIR/deploy-fleet-unit.sh"

# Parse arguments
parse_arguments "$@"

# Se nenhum input for informado, execute a função `interactive`
if [[ -z "$ENTITY" && -z "$ACTION" && -z "$NAME" && -z "${PARAMS[*]}" ]]; then
  interactive
  return
fi

# Validate input
validate_input

# Dispatch the action
dispatch_action