#!/bin/bash

set -e

# Instala pacotes básicos
apt-get update && apt-get install -y curl

# Instala KIND
echo "Instalando KIND..."
curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x /usr/local/bin/kind

# Instala kubectl
echo "Instalando kubectl..."
curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl

# Cria um cluster KIND
echo "Criando cluster Kubernetes..."
kind create cluster --name devcontainer-cluster