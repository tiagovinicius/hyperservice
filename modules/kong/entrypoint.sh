echo "Setting up dataplane"
CONTROL_PLANE_IP=172.19.0.4
export CONTAINER_IP=$(hostname -i)
echo "Container IP is $CONTAINER_IP"
kumactl config control-planes add --name=default --address=http://$CONTROL_PLANE_IP:5681
envsubst < ./dataplane.yml | kumactl apply -f -

echo "Starting Kong"
kong docker-start