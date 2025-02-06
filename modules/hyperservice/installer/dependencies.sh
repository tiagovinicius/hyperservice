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
    mv "$TEMP_DIR/kuma-2.9.2/bin/"* /usr/local/bin/
    rm -rf "$TEMP_DIR"
}

dependencies=(
    "install_dependency apt_installer docker.io docker 'docker --version'"
    "install_dependency apt_installer curl curl 'curl --version | head -n 1'"
    "install_dependency apt_installer unzip unzip 'echo unzip available'"
    "install_dependency apt_installer uuid-runtime uuidgen 'echo uuidgen available'"
    "install_dependency apt_installer yq yq 'yq --version'"
    "install_dependency apt_installer fzf fzf 'fzf --version'"
    "install_dependency apt_installer sshpass sshpass 'sshpass --version'"
    "install_dependency apt_installer tar tar 'tar --version'"
    "install_dependency apt_installer needrestart needrestart 'needrestart --version'"
    "install_dependency apt_installer gettext-base  gettext-base  'gettext-base --version'"
    "install_dependency apt_installer wget  wget  'wget --version'"
    "install_dependency apt_installer jq jq 'jq --version'"
    "install_dependency apt_installer coreutils coreutils 'coreutils --version'"
    "install_dependency apt_installer nano nano 'nano --version'"
    "install_dependency apt_installer iptables  iptables  'iptables --version'"
    "install_dependency apt_installer iptables-persistent iptables-persistent 'iptables-persistent --version'"
    "install_dependency apt_installer nftables nftables 'nftables --version'"
    "install_dependency apt_installer bash bash 'bash --version'"
    "install_dependency apt_installer build-essential build-essential 'build-essential --version'"
    "install_dependency apt_installer docker-compose docker-compose 'docker-compose --version'"
    "install_dependency apt_installer docker.io docker.io 'docker.io --version'"
    "install_dependency apt_installer gettext-base gettext-base 'gettext-base --version'"
    "install_dependency apt_installer iptables-persistent iptables-persistent 'iptables-persistent --version'"
    "install_dependency apt_installer sudo sudo 'sudo --version'"
    "install_dependency apt_installer uuid-runtime uuid-runtime 'uuid-runtime --version'"
    "install_dependency kuma_installer kuma kuma 'kuma-dp --version'"
    "install_dependency node_installer 'Node.js' node 'node -v'"
    "install_dependency npm_installer '@moonrepo/cli' moon 'moon --version'"
)

