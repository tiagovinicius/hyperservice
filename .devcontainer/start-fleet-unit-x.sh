#!/bin/bash

FLEET_UNIT_X_NAME="fleet-unit-x"
FLEET_UNIT_X_IMAGE_NAME="hyperservice-fleet-remote-simulator-image"
FLEET_UNIT_X_SSH_PORT=2222
FLEET_UNIT_X_SSH_USERNAME=root
FLEET_UNIT_X_SSH_FILE=~/.ssh/fleet-unit-x-host-key


ssh-keygen -t rsa -b 2048 -f $FLEET_UNIT_X_SSH_FILE -N "" 
chmod 600 "$FLEET_UNIT_X_SSH_FILE"

echo "The container $FLEET_UNIT_X_NAME is not running."
if docker ps -a -q -f name=$FLEET_UNIT_X_NAME | grep -q .; then
    echo "Removing the existing container $FLEET_UNIT_X_NAME..."
    docker rm -f -v $FLEET_UNIT_X_NAME
fi
echo "Starting a new container with port mapping $FLEET_UNIT_X_SSH_PORT:22..."
docker run -d \
    -p $FLEET_UNIT_X_SSH_PORT:22 \
    --name $FLEET_UNIT_X_NAME \
    -e PUBLIC_KEY="$(cat $FLEET_UNIT_X_SSH_FILE.pub)" \
    --privileged \
    $FLEET_UNIT_X_IMAGE_NAME

FLEET_UNIT_X_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $FLEET_UNIT_X_NAME)
echo "Container started. Connect via: ssh -i $FLEET_UNIT_X_SSH_FILE $FLEET_UNIT_X_SSH_USERNAME@$FLEET_UNIT_X_IP -p 22"


