# Exit on error
set -e

#-------------------------------------
# Setting up Git
echo "Configuring Git with user name: $GIT_NAME and user email: $GIT_EMAIL"
# Default SSH key file if not provided via environment variable
git_ssh_key_path="${GIT_SSH_KEY_PATH:-$HOME/.ssh/id_rsa}"

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to configure Git
configure_git() {
    echo "🔧 Configuring Git..."

    if ! command_exists git; then
        echo "⚠️ Git is not installed. Skipping Git configuration."
        return
    fi

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global safe.directory '*'
    git config --global --unset-all safe.directory
    git config --global safe.directory '*'
    git config --global core.editor "nano"
    git config pull.rebase false

    echo "✅ Git configuration completed!"
}

# Function to start SSH agent and add SSH key
setup_git_ssh() {
    echo "🔐 Setting up SSH agent..."

    if ! command_exists ssh-agent || ! command_exists ssh-add; then
        echo "⚠️ SSH agent or ssh-add not found. Skipping SSH setup."
        return
    fi

    eval "$(ssh-agent -s)" >/dev/null
    echo "✅ SSH agent started!"

    if [[ -f "$git_ssh_key_path" ]]; then
        ssh-add "$git_ssh_key_path"
        echo "✅ SSH key ($git_ssh_key_path) added!"
    else
        echo "⚠️ No SSH key found at $git_ssh_key_path. Skipping SSH key addition."
    fi
}

# Function to fix SSH folder permissions
fix_ssh_permissions() {
    if [[ -d ~/.ssh ]]; then
        echo "🔧 Changing ownership of SSH folder..."
        chown -R root:root ~/.ssh
        echo "✅ SSH folder ownership updated!"
    else
        echo "⚠️ SSH folder ~/.ssh does not exist. Skipping ownership change."
    fi
}

# ---------------------------------------------
# Adding aliases to apps
declare -A aliases=(
    ["hy-cp"]="moon hyperservice-control-plane:run"
    ["hy-dp"]="moon hyperservice-dataplane:run"
    ["hyctl"]="moon hyperservice-cli:run --"
)

add_aliases_to_shell() {
    local shell_config_file="$1"

    echo "🔗 Adding aliases to $shell_config_file..."

    for alias_name in "${!aliases[@]}"; do
        echo "🔍 Checking if alias $alias_name exists..."
        
        if ! grep -q "alias $alias_name=" "$shell_config_file"; then
            echo "alias $alias_name='${aliases[$alias_name]}'" >> "$shell_config_file"
            echo "✅ Added alias: $alias_name"
        else
            echo "⚠️ Alias $alias_name already exists"
        fi
    done
    
    echo "🔄 Sourcing $shell_config_file to apply changes..."
    source "$shell_config_file"
}

setup_aliases() {
    local shell=$(basename "$SHELL")
    echo "🖥️ Detected shell: $shell"

    case "$shell" in
        bash) add_aliases_to_shell "$HOME/.bashrc" ;;
        zsh) add_aliases_to_shell "$HOME/.zshrc" ;;
        fish)
            local fish_config="$HOME/.config/fish/config.fish"
            for alias_name in "${!aliases[@]}"; do
                if ! grep -q "alias $alias_name=" "$fish_config"; then
                    echo "alias $alias_name '${aliases[$alias_name]}'" >> "$fish_config"
                    echo "✅ Added alias: $alias_name"
                else
                    echo "⚠️ Alias $alias_name already exists"
                fi
            done
            source "$fish_config"
            ;;
        *)
            echo "⚠️ Shell not supported"
            ;;
    esac
    echo "🎉 Aliases added and applied successfully!"
}

# -------------------------------------------
# Setting up Moon
clean_moon_cache() {
    echo "🧹 Removing Moon cache..."
    rm -rf .moon/cache
    echo "✅ Moon cache removed!"
}

# -------------------------------------------
# Setting up Network
NETWORK_NAME="hyperservice-network"

connect_devcontainer_to_network() {
    echo "🌐 Checking if network '$NETWORK_NAME' is active..."

    if docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
        echo "✅ Network '$NETWORK_NAME' is active. Connecting devcontainer..."

        local container_name_or_id=$(hostname)

        echo "🔗 Connecting container '$container_name_or_id' to network '$NETWORK_NAME'..."
        if docker network connect "$NETWORK_NAME" "$container_name_or_id"; then
            echo "✅ Devcontainer connected to network '$NETWORK_NAME' successfully!"
        else
            echo "❌ Failed to connect the devcontainer to the network."
        fi
    else
        echo "⚠️ Network '$NETWORK_NAME' is not active. Please ensure the network is up."
    fi
}

configure_git
setup_git_ssh
fix_ssh_permissions
setup_aliases
clean_moon_cache
connect_devcontainer_to_network

echo "🚀 Setup complete!"
