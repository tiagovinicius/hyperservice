#!/bin/bash

$HYPERSERVICE_BIN_PATH/installer/install.sh

cd $HYPERSERVICE_WORKSPACE_PATH
hyperservice mesh-dp deploy

sleep infinity
