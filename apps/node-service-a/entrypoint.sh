#!/bin/bash
echo "Installing dependencies"
npm install

echo "Setting up dataplane"
CONTROL_PLANE_IP=172.19.0.5
CONTROL_PLANE_NAME=control-plane
CONTROL_PLANE_ADMIN_USER_TOKEN=$(cat /run/secrets/control-plane-admin-user-token)
export CONTAINER_IP=$(hostname -i)
kumactl config control-planes add \
  --name=default \
  --address=http://$CONTROL_PLANE_IP:5681 \
  --auth-type=tokens \
  --auth-conf token=${CONTROL_PLANE_ADMIN_USER_TOKEN}
envsubst < ./dataplane.yml | kumactl apply -f -
kumactl generate dataplane-token --tag kuma.io/service=service-a --valid-for=720h > /.token
kuma-dp run \
  --name service-a \
  --mesh default \
  --cp-address https://$CONTROL_PLANE_IP:5678 \
  --dataplane-token-file=/.token \
  2>&1 | tee logs/dataplane-logs.txt &

echo "Starting service"
node app.js \
  2>&1 | tee logs/app-logs.txt