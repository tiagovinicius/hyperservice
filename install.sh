#!/bin/bash

echo "Creating directories and files"
FILES=(
  "modules/kuma/tokens/.control-plane-admin-user-token"
)
for FILE in "${FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    mkdir -p "$(dirname "$FILE")"
    echo "token_content" > "$FILE"
  fi
done


echo "Linking Hyperservice cli in path"
HYPERSERVICE_LINK_PATH="/usr/local/bin/hyperservice"
HYPERSERVICE_TARGET_PATH="/workspace/apps/hyperservice/manage.sh"
[[ -e "$HYPERSERVICE_LINK_PATH" ]] && sudo rm -f "$HYPERSERVICE_LINK_PATH"
sudo ln -sf "$HYPERSERVICE_TARGET_PATH" "$HYPERSERVICE_LINK_PATH"
chmod +x /workspace/apps/hyperservice/manage.sh
export PATH=$PATH:/usr/local/bin

echo "Project installed with success."