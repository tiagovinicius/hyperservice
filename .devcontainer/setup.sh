set -e

#-------------------------------------
# Setting up Git
echo "Configuring Git with user name: $GIT_NAME and user email: $GIT_EMAIL"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global safe.directory '*'
git config --global --unset-all safe.directory
git config --global safe.directory '*'
git config --global core.editor "nano"
git config pull.rebase false

echo "Starting SSH agent..."
eval $(ssh-agent -s)

echo "Adding SSH key..."
ssh-add ~/.ssh/id_rsa

echo "Changing ownership of SSH folder..."
chown -R root:root ~/.ssh


#---------------------------------------------
# Adding alias to apps
declare -A aliases=(
    ["hycp"]="moon hyperservice-control-plane:run"
    ["hydp"]="moon hyperservice-dataplane:run"
    ["hyctl"]="moon hyperservice-cli:run"
)

add_aliases_to_shell() {
    local shell_config_file="$1"
    
    echo "Adding aliases to $shell_config_file..."
    
    for alias_name in "${!aliases[@]}"; do
        echo "Checking if alias $alias_name exists in $shell_config_file..."
        
        if ! grep -q "alias $alias_name=" "$shell_config_file"; then
            echo "alias $alias_name='${aliases[$alias_name]}'" >> "$shell_config_file"
            echo "Added alias: $alias_name"
        else
            echo "Alias $alias_name already exists"
        fi
    done
    
    echo "Sourcing $shell_config_file to apply changes..."
    source "$shell_config_file"
}

shell=$(basename "$SHELL")
echo "Detected shell: $shell"

case "$shell" in
    bash)
        add_aliases_to_shell "$HOME/.bashrc"
        ;;
    zsh)
        add_aliases_to_shell "$HOME/.zshrc"
        ;;
    fish)
        for alias_name in "${!aliases[@]}"; do
            if ! grep -q "alias $alias_name=" "$HOME/.config/fish/config.fish"; then
                echo "alias $alias_name '${aliases[$alias_name]}'" >> "$HOME/.config/fish/config.fish"
                echo "Added alias: $alias_name"
            else
                echo "Alias $alias_name already exists"
            fi
        done
        source "$HOME/.config/fish/config.fish"
        ;;
    *)
        echo "Shell not supported"
        ;;
esac

echo "Aliases added and applied successfully."


#-------------------------------------------
# Setting up Moon
echo "Removing moon cache."
rm -rf /workspaces/hyperservice/.moon/cache


#-------------------------------------------
# Setting up Network
NETWORK_NAME="hyperservice-network"

echo "Checking if network '$NETWORK_NAME' is active..."

network_exists=$(docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; echo $?)

if [ "$network_exists" -eq 0 ]; then
  echo "Network '$NETWORK_NAME' is active. Connecting devcontainer..."

  container_name_or_id=$(hostname)

  echo "Connecting container '$container_name_or_id' to network '$NETWORK_NAME'..."

  docker network connect "$NETWORK_NAME" "$container_name_or_id"

  if [ $? -eq 0 ]; then
    echo "Devcontainer connected to network '$NETWORK_NAME' successfully."
  else
    echo "Failed to connect the devcontainer to the network."
  fi
else
  echo "Network '$NETWORK_NAME' is not active. Please ensure the network is up."
fi
