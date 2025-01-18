dispatch_action() {
 

  # Verifica a ação informada
  if [[ -n "$HELP" && -z "$ACTION" ]]; then
    if [[ "$ENTITY" == "mesh" ]]; then
      mesh_usage
    elif [[ "$ENTITY" == "service" ]]; then
      service_usage
    else
      default_usage
    fi
  else
   # Default to 'service' only if ENTITY is explicitly required
    if [[ -z "$ENTITY" ]]; then
      ENTITY="service"
    fi

    if [[ "$ENTITY" == "mesh" ]]; then
      mesh_dispatch "$ACTION" "$SERVICES"
    elif [[ "$ENTITY" == "service" ]]; then
      service_dispatch "$ACTION" "$NAME" "$WORKDIR"
    else
      echo "Error: Unsupported entity '$ENTITY'."
      exit 1
    fi
  fi
}
