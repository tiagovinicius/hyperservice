#!/bin/bash

# Array of dependencies
dependencies=(
    "install_dependency apt_installer git git 'git --version'"
    "install_dependency apt_installer docker.io docker 'docker --version'"
    "install_dependency apt_installer curl curl 'curl --version | head -n 1'"
    "install_dependency apt_installer unzip unzip 'echo unzip available'"
    "install_dependency apt_installer sudo sudo 'sudo -V | head -n 1'"
    "install_dependency apt_installer uuid-runtime uuidgen 'echo uuidgen available'"
    "install_dependency apt_installer yq yq 'yq --version'"
    "install_dependency apt_installer fzf fzf 'fzf --version'"
    "install_dependency node_installer 'Node.js' node 'node -v'"
    "install_dependency npm_installer '@moonrepo/cli' moon 'moon --version'"
)
