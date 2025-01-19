#!/bin/bash

# Debug function
debug_echo() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "DEBUG: $*"
  fi
}

# Trim function
trim() {
  local var="$*"
  var="${var#"${var%%[![:space:]]*}"}"  # remove leading
  var="${var%"${var##[![:space:]]*}"}"  # remove trailing
  echo -n "$var"
}

# 'get_param_value' function
# key = e.g. "--recreate"
# type = "boolean" or "value"
# params = array of tokens
get_param_value() {
  local key="$1"
  local type="$2"
  shift 2
  local params=("$@")

  for p in "${params[@]}"; do
    debug_echo "get_param_value: checking '$p' vs. '$key' ($type)"

    # For boolean, check if p == key
    if [[ "$type" == "boolean" && "$p" == "$key" ]]; then
      echo "true"
      return
    fi

    # For value param, check if p starts with key=
    if [[ "$type" == "value" && "$p" =~ ^"${key}"= ]]; then
      echo "${p#${key}=}"
      return
    fi
  done

  # If not found
  if [[ "$type" == "boolean" ]]; then
    echo "false"
  else
    echo ""
  fi
}

# Main parse_arguments
parse_arguments() {
  if [[ "$#" -eq 0 ]]; then
    ENTITY=""
    ACTION=""
    NAME=""
    PARAMS=()
    return
  fi

  local args=("$@")
  debug_echo "Received args: ${args[*]}"

  ENTITY=""
  ACTION=""
  NAME=""
  PARAMS=()

  # 1) Check if first token is 'mesh' or 'service'
  if [[ "${args[0]}" == "mesh" || "${args[0]}" == "service" ]]; then
    ENTITY="${args[0]}"
    debug_echo "Parsed ENTITY='$ENTITY'"
    args=("${args[@]:1}")
  fi

  # 2) Collect all parameters that begin with '--'
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    local current="${args[$i]}"

    if [[ "$current" =~ ^-- ]]; then
      debug_echo "Param found => $current"
      PARAMS+=("$current")
      ((i++))
    else
      # Not a parameter => break
      break
    fi
  done

  # 3) The remainder are NAME / ACTION
  args=("${args[@]:$i}")
  local length=${#args[@]}

  if (( length == 0 )); then
    ACTION=""
    NAME=""
  else
    ACTION="${args[$((length-1))]}"
    if (( length > 1 )); then
      NAME="${args[$((length-2))]}"
    fi
  fi

  # Trim results
  ENTITY="$(trim "$ENTITY")"
  ACTION="$(trim "$ACTION")"
  NAME="$(trim "$NAME")"

  # 4) Extract known parameters
  WORKDIR=$(get_param_value "--workdir" "value" "${PARAMS[@]}")
  SERVICES=$(get_param_value "--services" "boolean" "${PARAMS[@]}")
  RECREATE=$(get_param_value "--recreate" "boolean" "${PARAMS[@]}")
  CLEAN=$(get_param_value "--clean" "boolean" "${PARAMS[@]}")
  HELP=$(get_param_value "--help" "boolean" "${PARAMS[@]}")
  NODE_NAME=$(get_param_value "--node" "value" "${PARAMS[@]}")
}




