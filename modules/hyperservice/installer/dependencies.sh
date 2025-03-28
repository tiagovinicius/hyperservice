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
    "install_dependency apt_installer curl curl 'curl --version | head -n 1'"
    "install_dependency apt_installer unzip unzip 'unzip -Z | head -n 1'"
    "install_dependency apt_installer uuid-runtime uuidgen 'uuidgen --version'"
    "install_dependency apt_installer yq yq 'yq --version'"
    "install_dependency apt_installer fzf fzf 'fzf --version'"
    "install_dependency apt_installer tar tar 'tar --version | head -n 1'"
    "install_dependency apt_installer needrestart needrestart 'needrestart --version | tail -n +2 | head -n 1'"
    "install_dependency apt_installer wget  wget  'wget --version | head -n 1'"
    "install_dependency apt_installer jq jq 'jq --version'"
    "install_dependency apt_installer coreutils cat 'cat --version | head -n 1'"
    "install_dependency apt_installer nano nano 'nano --version | head -n 1'"
    "install_dependency apt_installer iptables  iptables  'iptables --version'"
    "install_dependency apt_installer iptables-persistent iptables 'iptables --version'"
    "install_dependency apt_installer nftables nft 'nft --version'"
    "install_dependency apt_installer iproute2 ip 'ip -V'"
    "install_dependency apt_installer nmap nmap 'nmap --version | head -n 1'"
    "install_dependency apt_installer collectd collectd 'collectd -h | tail -n +21 | head -n 1'"
    "install_dependency kuma_installer kuma kuma-dp 'kuma-dp version'"
    "install_dependency node_installer 'Node.js' node 'node -v'"
    "install_dependency npm_installer '@moonrepo/cli' moon 'moon --version'"
)

