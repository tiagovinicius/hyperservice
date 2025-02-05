#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "Starting Hyperservice setup..."

# Step 1: Install dependencies using an absolute path
SCRIPT_DIR="$(realpath "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/..")"
echo "Running dependency installation..."
bash "$SCRIPT_DIR/installer/install-dependencies.sh"

# Step 2: Set up symbolic links
echo "Setting up symbolic links for Hyperservice..."

HYPERSERVICE_LINK_PATH="/usr/local/bin/hyperservice"
HYPERSERVICE_LINK_BIN_PATH="/usr/local/bin/hyperservice-bin"
HYPERSERVICE_SHORTLINK_PATH="/usr/local/bin/hy"

# Set the base path to WORKSPACE_PATH if set, or to an empty string otherwise
WORKSPACE_BASE_PATH="${WORKSPACE_PATH:+$WORKSPACE_PATH/}"

if [ -n "$HYPERSERVICE_DEV_PATH" ]; then
  echo "HYPERSERVICE_DEV_PATH is set to $HYPERSERVICE_DEV_PATH."
  HYPERSERVICE_TARGET_PATH="$(realpath "${WORKSPACE_BASE_PATH}${HYPERSERVICE_DEV_PATH}/cli.sh")"

  # Validate the target file exists
  if [ ! -f "$HYPERSERVICE_TARGET_PATH" ]; then
    echo "Error: Target file $HYPERSERVICE_TARGET_PATH does not exist."
    exit 1
  fi

  echo "Creating or updating symbolic link for $HYPERSERVICE_LINK_PATH..."
  sudo rm -f "$HYPERSERVICE_LINK_PATH"
  sudo ln -sf "$HYPERSERVICE_TARGET_PATH" "$HYPERSERVICE_LINK_PATH"
  sudo chmod +x "$HYPERSERVICE_LINK_PATH"
else
  echo "HYPERSERVICE_DEV_PATH is not set. Using default installation."
  echo "Creating or updating symbolic link for $HYPERSERVICE_LINK_PATH..."
  sudo rm -f "$HYPERSERVICE_LINK_PATH"
  sudo ln -sf "$SCRIPT_DIR/cli.sh" "$HYPERSERVICE_LINK_PATH"
  sudo chmod +x "$HYPERSERVICE_LINK_PATH"
fi

echo "Creating or updating symbolic link for $HYPERSERVICE_SHORTLINK_PATH..."
sudo rm -f "$HYPERSERVICE_SHORTLINK_PATH"
sudo ln -sf "$(realpath "$HYPERSERVICE_LINK_PATH")" "$HYPERSERVICE_SHORTLINK_PATH"
sudo chmod +x "$HYPERSERVICE_SHORTLINK_PATH"

REAL_SCRIPT_DIR="$(realpath "$SCRIPT_DIR")"
echo "Creating symbolic link to SCRIPT_DIR at $HYPERSERVICE_LINK_BIN_PATH..."
sudo rm -rf "$HYPERSERVICE_LINK_BIN_PATH"
sudo ln -sf "$SCRIPT_DIR" "$HYPERSERVICE_LINK_BIN_PATH"

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