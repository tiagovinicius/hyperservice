#!/bin/bash

# Load dependencies from external file
source "$(dirname "$0")/dependencies.sh"

echo "Installing required dependencies..."

if [ -z "${HYPERSERVICE_OFFLINE_INSTALL}" ] || [ "$HYPERSERVICE_OFFLINE_INSTALL" = false ]; then
    # Update package lists once
    sudo apt-get update -y
fi


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
        echo -e "Package is already installed: $package"
    else
        if [ "$HYPERSERVICE_OFFLINE_INSTALL" = true ]; then
            echo "Package is not installed: $package"
            echo "HYPERSERVICE_OFFLINE_INSTALL is set to true. All packages must be installed to proceed."
            exit 1
        fi
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

npm_installer() {
    npm install -g "$1"
}

# Execute each dependency installation
for dep in "${dependencies[@]}"; do
    eval $dep
done

echo "Dependencies installation completed."
