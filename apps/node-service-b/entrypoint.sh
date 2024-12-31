#!/bin/bash
echo "Installing dependencies"
npm install

echo "Setting up dataplane"
kumactl config control-planes add --name=my-kuma --address=http://172.18.0.2:5681
kumactl apply -f ./dataplane.yml

echo "Starting service"
node app.js