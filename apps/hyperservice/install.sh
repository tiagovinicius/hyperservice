#!/bin/bash
echo "Installing dependencies"
npm install
npm install --global @moonrepo/cli

echo "Creating /etc/shared/environment"
mkdir -p /etc/shared/environment

echo "Linking Hyperservice cli in path"
HYPERSERVICE_LINK_PATH="/usr/local/bin/hyperservice"
HYPERSERVICE_SHORTLINK_PATH="/usr/local/bin/hy"
HYPERSERVICE_TARGET_PATH="/workspace/apps/hyperservice/manage.sh"
for LINK_PATH in "$HYPERSERVICE_LINK_PATH" "$HYPERSERVICE_SHORTLINK_PATH"; do
  [[ -e "$LINK_PATH" ]] && sudo rm -f "$LINK_PATH"
  sudo ln -sf "$HYPERSERVICE_TARGET_PATH" "$LINK_PATH"
  sudo chmod +x "$LINK_PATH"
done
sudo chmod +x /workspace/apps/hyperservice/manage.sh
export PATH=$PATH:/usr/local/bin

echo "Project installed with success."