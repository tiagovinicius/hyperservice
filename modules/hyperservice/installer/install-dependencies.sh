#!/bin/bash

# Load dependencies from external file
source "$(dirname "$0")/dependencies.sh"

echo "Installing required dependencies using an array of functions..."

# Update package lists once
sudo apt-get update -y

# Function to check if a dependency is installed
check_dependency() {
    local dependency=$1
    command -v $dependency &> /dev/null
}

# General function to install a dependency using a custom installer function
install_dependency() {
    local installer_function=$1
    local package=$2
    local dependency=$3
    local post_install_command=$4  # Optional command to check version after install

    if check_dependency "$dependency"; then
        echo "$package is already installed: $($post_install_command)"
    else
        echo "Installing $package..."
        $installer_function "$package"
        echo "$package installed successfully."
        if [ -n "$post_install_command" ]; then
            echo "Version: $($post_install_command)"
        fi
    fi
}

# Custom installer functions
apt_installer() {
    sudo apt-get install -y "$1"
}

node_installer() {
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
}

npm_installer() {
    npm install -g "$1"
}

# Execute each dependency installation
for dep in "${dependencies[@]}"; do
    eval $dep
done

echo "Dependencies installation completed."
