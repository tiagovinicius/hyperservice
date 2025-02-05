#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Caminho de instalação no usuário local
HYPERSERVICE_LINK_PATH="/usr/local/bin/hyperservice"

# URL do repositório como .zip
REPO_URL="https://github.com/tiagovinicius/hyperservice/archive/refs/heads/main.zip"

# Criar diretório temporário para o download
TEMP_DIR=$(mktemp -d)

echo "Downloading Hyperservice CLI from GitHub..."

# Baixar o repositório como .zip
curl -L "$REPO_URL" -o "$TEMP_DIR/hyperservice.zip"

# Extrair o conteúdo do .zip
unzip -q "$TEMP_DIR/hyperservice.zip" -d "$TEMP_DIR"

# Remover instalação anterior, se existir
if [ -d "$HYPERSERVICE_LINK_PATH" ]; then
    echo "Removing existing installation at $HYPERSERVICE_LINK_PATH..."
    rm -rf "$HYPERSERVICE_LINK_PATH"
fi

# Mover os arquivos extraídos para o caminho local
echo "Installing Hyperservice CLI to $HYPERSERVICE_LINK_PATH..."
mkdir -p "$HYPERSERVICE_LINK_PATH"
mv "$TEMP_DIR/hyperservice-main/modules/hyperservice/"* "$HYPERSERVICE_LINK_PATH"

# Dar permissão de execução ao diretório e seus scripts
chmod -R +x "$HYPERSERVICE_LINK_PATH"

# Limpar o diretório temporário
rm -rf "$TEMP_DIR"

echo "Hyperservice CLI installed successfully at $HYPERSERVICE_LINK_PATH."

# Verificar se o arquivo install.sh existe no diretório e executá-lo
INSTALL_SCRIPT="$HYPERSERVICE_LINK_PATH/install.sh"
if [ -f "$INSTALL_SCRIPT" ]; then
    echo "Running install.sh..."
    bash "$INSTALL_SCRIPT"
else
    echo "Error: install.sh not found in $HYPERSERVICE_LINK_PATH."
    exit 1
fi
