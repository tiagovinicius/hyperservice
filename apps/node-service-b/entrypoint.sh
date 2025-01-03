#!/bin/bash
echo "Installing dependencies"
npm install

echo "Setting up dataplane"
DATA_PLANE_NAME=service-b
CONTROL_PLANE_IP=172.19.0.4
CONTROL_PLANE_NAME=control-plane
CONTROL_PLANE_ADMIN_USER_TOKEN=$(cat /run/secrets/control-plane-admin-user-token)
export CONTAINER_IP=$(hostname -i)
kumactl config control-planes add \
  --name=default \
  --address=http://$CONTROL_PLANE_IP:5681 \
  --auth-type=tokens \
  --auth-conf token=${CONTROL_PLANE_ADMIN_USER_TOKEN}
kumactl generate dataplane-token --tag kuma.io/service=$DATA_PLANE_NAME --valid-for=720h > /.token
useradd -u 5678 -U kuma-dp
kumactl install transparent-proxy \
  --kuma-dp-user kuma-dp \
  --redirect-dns \
  --exclude-inbound-ports 22
runuser -u kuma-dp -- \
  kuma-dp run \
    --cp-address https://$CONTROL_PLANE_IP:5678 \
    --dataplane-token-file=/.token \
    --dataplane="$(envsubst < ./dataplane.yml)" \
    2>&1 | tee logs/dataplane-logs.txt &

echo "Starting service"
node app.js \
  2>&1 | tee logs/app-logs.txt