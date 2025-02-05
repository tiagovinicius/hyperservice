#!/bin/bash
git config --global --add safe.directory /workspace

echo "Waiting control plane to be running"
elapsed=0
sleep_interval=1
while [ "$(cat /etc/shared/environment/CONTROL_PLANE_STATUS)" != "running" ]; do
  echo "Waiting for control plane to be running..."
  sleep $sleep_interval
  elapsed=$((elapsed + sleep_interval))

  if [ $sleep_interval -lt 60 ]; then
    sleep_interval=$((sleep_interval * 2))
    if [ $sleep_interval -gt 60 ]; then
      sleep_interval=60
    fi
  fi
done

echo "Installing dependencies"
npm install
npm install --global @moonrepo/cli

echo "Creating directories"
mkdir -p logs

echo "Connecting to mesh"
export CONTAINER_IP=$(hostname -i)
CONTROL_PLANE_IP=$(cat /etc/shared/environment/CONTROL_PLANE_IP)
CONTROL_PLANE_ADMIN_USER_TOKEN=$(cat /etc/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN)
kumactl config control-planes add \
  --name=default \
  --address=http://$CONTROL_PLANE_IP:5681 \
  --auth-type=tokens \
  --auth-conf token=${CONTROL_PLANE_ADMIN_USER_TOKEN}

echo "Applying policies"
POLICIES_DIR=".hyperservice/policies"
for FILE in $(ls "$POLICIES_DIR"/*.yml | sort); do
  echo "Applying file $FILE"
  echo "$(envsubst < "$FILE")" | kumactl apply -f -
done

echo "Setting up dataplane"
kumactl generate dataplane-token --tag kuma.io/service=$DATAPLANE_NAME --valid-for=720h > /.token
useradd -u 5678 -U kuma-dp
kumactl install transparent-proxy \
  --kuma-dp-user kuma-dp \
  --redirect-dns \
  --exclude-inbound-ports 22
runuser -u kuma-dp -- \
  kuma-dp run \
    --cp-address https://$CONTROL_PLANE_IP:5678 \
    --dataplane-token-file=/.token \
    --dataplane="$(envsubst < .hyperservice/dataplane.yml)" \
    2>&1 | tee logs/dataplane-logs.txt &

echo "Starting service $SERVICE_NAME"
moon $SERVICE_NAME:dev \
  2>&1 | tee logs/app-logs.txt
