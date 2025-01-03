echo "Setting up Git"
git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL

echo "Setting up kumactl"
CONTROL_PLANE_IP=172.19.0.4
CONTROL_PLANE_NAME=control-plane
export CONTAINER_IP=$(hostname -i)
CONTROL_PLANE_ADMIN_USER_TOKEN=$(bash -c "docker exec -it $CONTROL_PLANE_NAME curl http://localhost:5681/global-secrets/admin-user-token" | jq -r .data | base64 -d)
echo "$CONTROL_PLANE_ADMIN_USER_TOKEN" > modules/kuma/tokens/.control-plane-admin-user
echo "Container IP is $CONTAINER_IP"
kumactl config control-planes add \
 --name default \
 --address http://$CONTROL_PLANE_IP:5681 \
 --auth-type=tokens \
 --auth-conf token=$CONTROL_PLANE_ADMIN_USER_TOKEN \
 --skip-verify

