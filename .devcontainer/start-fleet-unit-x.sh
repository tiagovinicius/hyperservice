#!/bin/bash

FLEET_UNIT_X_NAME="fleet-unit-x"
FLEET_UNIT_X_IMAGE_NAME="rastasheep/ubuntu-sshd:18.04"
FLEET_UNIT_X_SSH_PORT=2222

if docker ps -q -f name=$FLEET_UNIT_X_NAME | grep -q .; then
    echo "The container $FLEET_UNIT_X_NAME is running. Restarting..."
    docker restart $FLEET_UNIT_X_NAME
else
    echo "The container $FLEET_UNIT_X_NAME is not running."
    if docker ps -a -q -f name=$FLEET_UNIT_X_NAME | grep -q .; then
        echo "Removing the existing container $FLEET_UNIT_X_NAME..."
        docker rm -f $FLEET_UNIT_X_NAME
    fi
    echo "Starting a new container with port mapping $FLEET_UNIT_X_SSH_PORT:22..."
    docker run -d -p $FLEET_UNIT_X_SSH_PORT:22 --name $FLEET_UNIT_X_NAME -e ROOT_PASSWORD=root --privileged $FLEET_UNIT_X_IMAGE_NAME
    echo "Container started. Connect via: ssh root@localhost -p $FLEET_UNIT_X_SSH_PORT"
fi

FLEET_UNIT_X_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $FLEET_UNIT_X_NAME)

echo "Fleet unit x IP: $FLEET_UNIT_X_IP"

ssh-keygen -t rsa -b 2048 -f ~/.ssh/fleet-unit-x-host-key -N "" 
sshpass -p 'root' ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@$FLEET_UNIT_X_IP


