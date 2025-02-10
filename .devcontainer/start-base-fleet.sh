#!/bin/bash

FLEET_UNIT_X_NAME="fleet-unit-x"
FLEET_UNIT_X_IMAGE_NAME="hyperservice-fleet-remote-simulator-image"
FLEET_UNIT_X_SSH_PORT=2222
FLEET_UNIT_X_SSH_USERNAME=root
FLEET_UNIT_X_SSH_FILE=/etc/hyperservice/shared/ssh/fleet-unit-x-host-key

mkdir -p /etc/hyperservice/shared/ssh/

if [ "$(docker ps -q -f name=$FLEET_UNIT_X_NAME)" ]; then
    echo "The container $FLEET_UNIT_X_NAME is running. Stopping and removing it..."
    docker stop $FLEET_UNIT_X_NAME
    docker rm $FLEET_UNIT_X_NAME
elif [ "$(docker ps -aq -f name=$FLEET_UNIT_X_NAME)" ]; then
    echo "The container $FLEET_UNIT_X_NAME exists but is not running. Removing it..."
    docker rm $FLEET_UNIT_X_NAME
fi

if [ ! -f "$FLEET_UNIT_X_SSH_FILE" ]; then
    ssh-keygen -t rsa -b 2048 -f $FLEET_UNIT_X_SSH_FILE -N ""
    chmod 600 "$FLEET_UNIT_X_SSH_FILE"
    echo "SSH key generated at $FLEET_UNIT_X_SSH_FILE"
else
    echo "Existing SSH key found, reusing it."
fi

docker run -d \
    -p $FLEET_UNIT_X_SSH_PORT:22 \
    --name $FLEET_UNIT_X_NAME \
    -e PUBLIC_KEY="$(cat $FLEET_UNIT_X_SSH_FILE.pub)" \
    --privileged \
    $FLEET_UNIT_X_IMAGE_NAME

FLEET_UNIT_X_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $FLEET_UNIT_X_NAME)
echo "Container started. Connect via: ssh -i $FLEET_UNIT_X_SSH_FILE $FLEET_UNIT_X_SSH_USERNAME@$FLEET_UNIT_X_IP -p 22"

if [ "$(docker ps -q -f name=grafana)" ]; then
    echo "The container grafana is running. Stopping and removing it..."
    docker stop grafana
    docker rm grafana
elif [ "$(docker ps -aq -f name=grafana)" ]; then
    echo "The container grafana exists but is not running. Removing it..."
    docker rm grafana
fi
docker run -d --name grafana -p 3000:3000 grafana/grafana:8.5.2

if [ "$(docker ps -q -f name=prometheus)" ]; then
    echo "The container prometheus is running. Stopping and removing it..."
    docker stop prometheus
    docker rm prometheus
elif [ "$(docker ps -aq -f name=prometheus)" ]; then
    echo "The container prometheus exists but is not running. Removing it..."
    docker rm prometheus
fi
docker run -d \
    --name prometheus \
    -p 9090:9090 \
    -v /usr/local/bin/hyperservice-bin/common-services/observability/config:/etc/prometheus \
    prom/prometheus
    