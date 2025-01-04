echo "Setting up Git"
git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL

echo "LOCAL_WORKSPACE_FOLDER=$LOCAL_WORKSPACE_FOLDER" >> /etc/environment
echo "Local workspace folder is $LOCAL_WORKSPACE_FOLDER"

echo "Setting up kumactl"
CONTROL_PLANE_NAME=control-plane
export CONTROL_PLANE_IP=$(hostname -i)
echo "CONTROL_PLANE_IP=$CONTROL_PLANE_IP" >> /etc/environment
echo "Control plane IP is $CONTROL_PLANE_IP"
export CONTROL_PLANE_ADMIN_USER_TOKEN=$(bash -c "docker exec -it $CONTROL_PLANE_NAME curl http://localhost:5681/global-secrets/admin-user-token" | jq -r .data | base64 -d)
echo "CONTROL_PLANE_ADMIN_USER_TOKEN=$CONTROL_PLANE_ADMIN_USER_TOKEN" >> /etc/environment
echo "Control plane admin user token is $CONTROL_PLANE_ADMIN_USER_TOKEN"
kumactl config control-planes add \
 --name default \
 --address http://localhost:5681 \
 --skip-verify
