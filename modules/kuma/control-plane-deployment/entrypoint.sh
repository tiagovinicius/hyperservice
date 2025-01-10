echo "Setting CONTROL_PLANE_STATUS to initializing"
flock /etc/shared/environment/CONTROL_PLANE_STATUS \
  -c 'echo "initializing" > /etc/shared/environment/CONTROL_PLANE_STATUS'

echo "Hooking CONTROL_PLANE_STATUS to stopped when control plane is about to be done"
trap 'flock /etc/shared/environment/CONTROL_PLANE_STATUS -c "echo stopped > /etc/shared/environment/CONTROL_PLANE_STATUS"' SIGTERM SIGINT SIGKILL

echo "Setting LOCAL_WORKSPACE_FOLDER"
flock /etc/shared/environment/LOCAL_WORKSPACE_FOLDER \
  -c 'echo $LOCAL_WORKSPACE_FOLDER > /etc/shared/environment/LOCAL_WORKSPACE_FOLDER'
echo "Local workspace folder is $LOCAL_WORKSPACE_FOLDER"

echo "Starting control plane"
kuma-cp run > cp-logs.txt 2>&1 &
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

echo "Setting up controle plane cli"
CONTROL_PLANE_NAME=control-plane
export CONTROL_PLANE_IP=$(hostname -i)
flock /etc/shared/environment/CONTROL_PLANE_IP \
  -c 'echo $CONTROL_PLANE_IP > /etc/shared/environment/CONTROL_PLANE_IP'
export CONTROL_PLANE_ADMIN_USER_TOKEN=$(bash -c "docker exec -it $CONTROL_PLANE_NAME curl http://localhost:5681/global-secrets/admin-user-token" | jq -r .data | base64 -d)
flock /etc/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN \
  -c 'echo $CONTROL_PLANE_ADMIN_USER_TOKEN > /etc/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN'
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

echo "Setting CONTROL_PLANE_STATUS to running"
flock /etc/shared/environment/CONTROL_PLANE_STATUS \
  -c 'echo "running" > /etc/shared/environment/CONTROL_PLANE_STATUS'