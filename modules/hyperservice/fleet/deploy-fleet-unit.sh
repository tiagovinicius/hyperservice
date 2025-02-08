#!/bin/bash

set -e

deploy_fleet_unit() {
  service_name=$1
  workdir=$2
  host=$3
  port=$4
  username=$5
  key_file=$6

  if [ -n "$key_file" ]; then
    ssh_cmd="ssh -o StrictHostKeyChecking=no -p $port -i $key_file $username@$host"
  else
    ssh_cmd="ssh -o StrictHostKeyChecking=no -p $port $username@$host"
  fi

  if [ ! -d "$HYPERSERVICE_BIN_PATH" ]; then
    echo "Local hyperservice path $HYPERSERVICE_BIN_PATH does not exist."
    return 1
  fi
  tar -czf - -C "$HYPERSERVICE_BIN_PATH" . | $ssh_cmd "mkdir -p $HYPERSERVICE_BIN_PATH && tar --overwrite -xzf - -C $HYPERSERVICE_BIN_PATH"

  $ssh_cmd "mkdir -p $HYPERSERVICE_WORKSPACE_PATH"

  for dir in "$workdir" ".moon" ".hyperservice"; do
    if [ -d "$dir" ]; then
      remote_subdir="$HYPERSERVICE_WORKSPACE_PATH/$dir"
      tar -czf - -C "$HYPERSERVICE_CURRENT_WORKSPACE_PATH/$dir" . | $ssh_cmd "mkdir -p $remote_subdir && tar -xzf - -C $remote_subdir"
    fi
  done

  $ssh_cmd "bash $HYPERSERVICE_BIN_PATH/installer/install.sh"

  base_name="${service_name}-$(uuidgen | cut -c1-8)"
  CONTROL_PLANE_IP=$(cat $HYPERSERVICE_SHARED_ENVIRONMENT/CONTROL_PLANE_IP 2>/dev/null || true)
  CONTROL_PLANE_ADMIN_USER_TOKEN=$(cat $HYPERSERVICE_SHARED_ENVIRONMENT/CONTROL_PLANE_ADMIN_USER_TOKEN 2>/dev/null || true)

  # Remote configuration commands
  commands=(
    "sudo mkdir -p /etc/hyperservice/shared/environment/ && sudo chmod -R 777 /etc/hyperservice/shared/environment/"
    "echo \"$CONTROL_PLANE_IP\" > /etc/hyperservice/shared/environment/CONTROL_PLANE_IP"
    "echo \"$CONTROL_PLANE_ADMIN_USER_TOKEN\" > /etc/hyperservice/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN"
    "cd $HYPERSERVICE_WORKSPACE_PATH/ && hyperservice mesh-dp deploy"
    "cd $HYPERSERVICE_WORKSPACE_PATH/ && hyperservice --workdir=\"$HYPERSERVICE_WORKSPACE_PATH/$workdir\" --node=\"$base_name\" \"$service_name\" --service-only start"
  )

  # Execute remote commands
  for cmd in "${commands[@]}"; do
    $ssh_cmd "$cmd"
  done
}
