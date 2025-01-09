echo "Setting up Git"
git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL
git config --global --add safe.directory /workspace

echo "Setting CONTROL_PLANE_STATUS to initializing"
flock /etc/shared/environment/CONTROL_PLANE_STATUS -c 'echo "initializing" > /etc/shared/environment/CONTROL_PLANE_STATUS'

echo "Hooking CONTROL_PLANE_STATUS to stopped when control plane is about to be done"
trap 'flock /etc/shared/environment/CONTROL_PLANE_STATUS -c "echo stopped > /etc/shared/environment/CONTROL_PLANE_STATUS"' SIGTERM SIGINT SIGKILL


echo "LOCAL_WORKSPACE_FOLDER=$LOCAL_WORKSPACE_FOLDER" >> /etc/environment
echo "Local workspace folder is $LOCAL_WORKSPACE_FOLDER"

echo "Setting up kumactl"
CONTROL_PLANE_NAME=control-plane
export CONTROL_PLANE_IP=$(hostname -i)
echo "CONTROL_PLANE_IP=$CONTROL_PLANE_IP" >> /etc/environment
export CONTROL_PLANE_ADMIN_USER_TOKEN=$(bash -c "docker exec -it $CONTROL_PLANE_NAME curl http://localhost:5681/global-secrets/admin-user-token" | jq -r .data | base64 -d)
echo "CONTROL_PLANE_ADMIN_USER_TOKEN=$CONTROL_PLANE_ADMIN_USER_TOKEN" >> /etc/environment
kumactl config control-planes add \
 --name default \
 --address http://localhost:5681 \
 --skip-verify

echo "Applying policies"
POLICIES_DIR="/workspace/.hyperservice/policies"
for FILE in $(ls "$POLICIES_DIR"/*.yml | sort); do
    echo "$(envsubst < "$FILE")" | kumactl apply -f -
done

echo "Installing observability"
kumactl install observability > /dev/null


echo "Waiting control plane to be running"
timeout=300
elapsed=0
while ! curl -sf http://localhost:5681/ > /dev/null 2>&1; do
  if [ $elapsed -ge $timeout ]; then
    echo "Timeout waiting for control plane to be running."
    exit 1
  fi
  echo "Waiting for control plane to be running..."
  sleep 5
  elapsed=$((elapsed + 5))
done
flock /etc/shared/environment/CONTROL_PLANE_STATUS -c 'echo "running" > /etc/shared/environment/CONTROL_PLANE_STATUS'