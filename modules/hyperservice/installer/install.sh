#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "Starting Hyperservice setup..."

HYPERSERVICE_REAL_BIN_PATH="$(realpath "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/..")"
HYPERSERVICE_PATH="/usr/local/bin/hyperservice"
HYPERSERVICE_BIN_PATH="/usr/local/bin/hyperservice-bin"
HYPERSERVICE_SHORT_PATH="/usr/local/bin/hy"
HYPERSERVICE_SHARED_ENVIROMENT="/etc/hyperservice/shared/environment"
HYPERSERVICE_SHARED_SSH="/etc/hyperservice/shared/ssh"
HYPERSERVICE_SHARED_CONFIG="/etc/hyperservice/shared/config"
HYPERSERVICE_GRAFANA_DATA_VOLUME="hyperservice-grafana-data"

echo "Running dependency installation..."
bash "$HYPERSERVICE_REAL_BIN_PATH/installer/install-dependencies.sh"

echo "Provinioning storage resources..."
docker volume create $HYPERSERVICE_GRAFANA_DATA_VOLUME
mkdir -p $HYPERSERVICE_BIN_PATH
mkdir -p $HYPERSERVICE_SHARED_ENVIROMENT
mkdir -p $HYPERSERVICE_SHARED_SSH
mkdir -p $HYPERSERVICE_SHARED_CONFIG

echo "Setting up symbolic links for Hyperservice..."

if [ -n "$HYPERSERVICE_DEV_PATH" ]; then
  echo "HYPERSERVICE_DEV_PATH is set to $HYPERSERVICE_DEV_PATH."
  HYPERSERVICE_TARGET_PATH="$(realpath "${HYPERSERVICE_CURRENT_WORKSPACE_PATH}${HYPERSERVICE_DEV_PATH}/cli_dev.sh")"

  # Validate the target file exists
  if [ ! -f "$HYPERSERVICE_TARGET_PATH" ]; then
    echo "Error: Target file $HYPERSERVICE_TARGET_PATH does not exist."
    exit 1
  fi

  echo "Creating or updating symbolic link for $HYPERSERVICE_PATH..."
  rm -f "$HYPERSERVICE_PATH"
  ln -sf "$HYPERSERVICE_TARGET_PATH" "$HYPERSERVICE_PATH"
  chmod +x "$HYPERSERVICE_PATH"
else
  echo "HYPERSERVICE_DEV_PATH is not set. Using default installation."
  echo "Creating or updating symbolic link for $HYPERSERVICE_PATH..."
  rm -f "$HYPERSERVICE_PATH"
  ln -sf "$HYPERSERVICE_BIN_PATH/cli.sh" "$HYPERSERVICE_PATH"
  chmod +x "$HYPERSERVICE_PATH"
fi

echo "Creating or updating symbolic link for $HYPERSERVICE_SHORT_PATH..."
rm -f "$HYPERSERVICE_SHORT_PATH"
ln -sf "$(realpath "$HYPERSERVICE_PATH")" "$HYPERSERVICE_SHORT_PATH"
chmod +x "$HYPERSERVICE_SHORT_PATH"

add_to_shell_profile() {
  local profile=$1
  if [ -f "$profile" ]; then
    if ! grep -q 'export PATH=/usr/local/bin:$PATH' "$profile"; then
      echo "Adding /usr/local/bin to $profile..."
      echo 'export PATH=/usr/local/bin:$PATH' >> "$profile"
    fi
  fi
}

add_to_shell_profile "$HOME/.bashrc"
add_to_shell_profile "$HOME/.zshrc"
add_to_shell_profile "$HOME/.profile"
add_to_shell_profile "$HOME/.bash_profile"

if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
  echo "Adding /usr/local/bin to the current PATH..."
  export PATH=/usr/local/bin:$PATH
fi

echo "Setup completed successfully."