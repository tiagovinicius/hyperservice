#!/bin/bash

get_param_value() {
  local param="$1"
  local type="$2"  # "boolean" or "value"
  shift 2
  local params=("$@")
  
  for ((i = 0; i < ${#params[@]}; i++)); do
    if [[ "${params[i]}" == "$param" ]]; then
      if [[ "$type" == "boolean" ]]; then
        echo "true"
        return
      elif [[ "$type" == "value" ]]; then
        if [[ $((i + 1)) -lt ${#params[@]} && "${params[i + 1]}" != --* ]]; then
          echo "${params[i + 1]}"
          return
        else
          echo "Error: $param requires a value." >&2
          exit 1
        fi
      else
        echo "Error: Invalid type specified for $param." >&2
        exit 1
      fi
    fi
  done
  
  if [[ "$type" == "boolean" ]]; then
    echo "false"
  else
    echo ""
  fi
}

reconstruct_input() {
  local input="$ENTITY"
  [[ "${#PARAMS[@]}" -gt 0 ]] && input+=" ${PARAMS[*]}"
  [[ -n "$NAME" ]] && input+=" $NAME"
  input+=" $ACTION"
  echo "$input"
}

trim() {
    echo "$1" | sed 's/^ *//;s/ *$//' | tr -d '\n' | tr -d '\r' | tr -d '\t'  # Remove quebras de linha, retornos de carro e tabulação
}

validate_input() {
  local validations=("$@")
  local input=$(reconstruct_input)
  input=$(trim "$input")
  local match_found=false

  # Execute dynamic validation functions
  for validation in "${validations[@]}"; do
    $validation || exit 1
  done

  # Dynamically replace environment variables in rules
  local processed_rules=()
  for rule in "${rules[@]}"; do
    local processed_rule="$rule"
    # Substituir todas as variáveis de ambiente presentes na regra
    while [[ "$processed_rule" =~ \$[A-Za-z_][A-Za-z0-9_]* ]]; do
      local var_name="${BASH_REMATCH[0]}"     # Nome da variável (ex: $WORKDIR)
      # Remover o caractere `$` do nome da variável
      local clean_var_name="${var_name:1}"
      # Validar se o nome da variável é válido
      if [[ ! "$clean_var_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "Error: Invalid variable name detected: $clean_var_name" >&2
        exit 1
      fi
      # Substituir por valor vazio se não definido
      local var_value="${!clean_var_name:-}"
      processed_rule="${processed_rule//$var_name/$var_value}"
    done
    processed_rules+=("$processed_rule")
  done

  # Match against predefined rules
  for rule in "${processed_rules[@]}"; do
    local expected="$(trim "${rule%%|*}")"
    local description="$(trim "${rule##*|}")"
    if [[ "$input" == "$expected" ]]; then
      match_found=true
      debug_echo "Match found: $description"
      break
    fi
  done

  if ! $match_found; then
    echo "Error: Invalid input combination: $input"
    echo "Hint: Ensure your input matches one of the following rules:"
    for rule in "${rules[@]}"; do
      echo "- ${rule##*|}"
    done
    exit 1
  fi
}
