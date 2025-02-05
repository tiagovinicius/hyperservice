#!/bin/bash

# Get the directory where the script is located
HYPERSERVICE_REAL_BIN_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Caminho de instalação no usuário local
HYPERSERVICE_PATH="/usr/local/bin/hyperservice-bin"

# URL do repositório como .zip
repo_url="https://github.com/tiagovinicius/hyperservice/archive/refs/heads/main.zip"

# Criar diretório temporário para o download
temp_dir=$(mktemp -d)

echo "Downloading Hyperservice CLI from GitHub..."

# Baixar o repositório como .zip
curl -L "$repo_url" -o "$temp_dir/hyperservice.zip"

# Extrair o conteúdo do .zip
unzip -q "$temp_dir/hyperservice.zip" -d "$temp_dir"

# Remover instalação anterior, se existir
if [ -d "$HYPERSERVICE_PATH" ]; then
    echo "Removing existing installation at $HYPERSERVICE_PATH..."
    rm -rf "$HYPERSERVICE_PATH"
fi

# Mover os arquivos extraídos para o caminho local
echo "Installing Hyperservice CLI to $HYPERSERVICE_PATH..."
mkdir -p "$HYPERSERVICE_PATH"
mv "$temp_dir/hyperservice-main/modules/hyperservice/"* "$HYPERSERVICE_PATH"

# Dar permissão de execução ao diretório e seus scripts
chmod -R +x "$HYPERSERVICE_PATH"

# Limpar o diretório temporário
rm -rf "$temp_dir"

echo "Hyperservice CLI installed successfully at $HYPERSERVICE_PATH."

# Verificar se o arquivo install.sh existe no diretório e executá-lo
install_script="$HYPERSERVICE_PATH/install.sh"
if [ -f "$install_script" ]; then
    echo "Running install.sh..."
    bash "$install_script"
else
    echo "Error: install.sh not found in $HYPERSERVICE_PATH."
    exit 1
fi
