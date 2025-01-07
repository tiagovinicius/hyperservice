#!/bin/bash
echo "Installing dependencies"
npm install
npm install --global @moonrepo/cli

echo "Linking Hyperservice cli in path"
HYPERSERVICE_LINK_PATH="/usr/local/bin/hyperservice"
HYPERSERVICE_SHORTLINK_PATH="/usr/local/bin/hy"
HYPERSERVICE_TARGET_PATH="/workspace/apps/hyperservice/manage.sh"
[[ -e "$HYPERSERVICE_LINK_PATH" ]] && sudo rm -f "$HYPERSERVICE_LINK_PATH"
[[ -e "$HYPERSERVICE_SHORTLINK_PATH" ]] && sudo rm -f "$HYPERSERVICE_SHORTLINK_PATH"
sudo ln -sf "$HYPERSERVICE_TARGET_PATH" "$HYPERSERVICE_LINK_PATH"
sudo ln -sf "$HYPERSERVICE_TARGET_PATH" "$HYPERSERVICE_SHORTLINK_PATH"
chmod +x /workspace/apps/hyperservice/manage.sh
export PATH=$PATH:/usr/local/bin

echo "Project installed with success."