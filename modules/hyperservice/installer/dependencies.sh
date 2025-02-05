#!/bin/bash

node_installer() {
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
}

kuma_installer() {
    TEMP_DIR=$(mktemp -d)
    (
        cd "$TEMP_DIR" || exit
        curl -L https://kuma.io/installer.sh | VERSION=2.9.2 sh -
    )
    sudo mv "$TEMP_DIR/kuma-2.9.2/bin/"* /usr/local/bin/
    rm -rf "$TEMP_DIR"
}

dependencies=(
    "install_dependency apt_installer git git 'git --version'"
    "install_dependency apt_installer docker.io docker 'docker --version'"
    "install_dependency apt_installer curl curl 'curl --version | head -n 1'"
    "install_dependency apt_installer unzip unzip 'echo unzip available'"
    "install_dependency apt_installer sudo sudo 'sudo -V | head -n 1'"
    "install_dependency apt_installer uuid-runtime uuidgen 'echo uuidgen available'"
    "install_dependency apt_installer yq yq 'yq --version'"
    "install_dependency apt_installer fzf fzf 'fzf --version'"
    "install_dependency apt_installer sshpass sshpass 'sshpass --version'"
    "install_dependency kuma_installer 'Kuma' kuma 'kuma-dp --version'"
    "install_dependency node_installer 'Node.js' node 'node -v'"
    "install_dependency npm_installer '@moonrepo/cli' moon 'moon --version'"
)
