#!/bin/bash

mesh_dp_dispatch() {
  local action="$1"
  local services="$2"
  
  case $action in
    deploy)
      mesh_dp_deploy 
      ;;
    *)
      echo "Error: Unsupported action '$action' for mesh-dp."
      exit 1
      ;;
  esac
}
