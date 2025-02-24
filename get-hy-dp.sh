#!/bin/bash

# GitHub repository details
REPO_OWNER="tiagovinicius"
REPO_NAME="hyperservice"
BIN_NAME="hy-dp" 

# Determine OS and ARCH if not provided
OS=${OS:-$(uname | tr '[:upper:]' '[:lower:]')}
ARCH=${ARCH:-$(uname -m)}

# Normalize architecture naming
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="armv7" ;;
    *) echo "❌ Unsupported architecture: $ARCH" && exit 1 ;;
esac

# Get the latest release tag
echo "🔍 Fetching latest release..."
LATEST_TAG=$(curl -sL "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest" | grep '"tag_name":' | awk -F'"' '{print $4}')

if [[ -z "$LATEST_TAG" ]]; then
    echo "❌ Failed to get the latest release tag."
    exit 1
fi

echo "📦 Latest release: $LATEST_TAG"

# Fetch the list of assets in the latest release
ASSET_LIST=$(curl -sL "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest" | grep '"name":' | awk -F'"' '{print $4}')

# Find the correct asset name based on BIN_NAME, OS, and ARCH
FILE_NAME=$(echo "$ASSET_LIST" | grep -E "^${BIN_NAME}-[0-9]+\.[0-9]+\.[0-9]+-${OS}-${ARCH}$")

if [[ -z "$FILE_NAME" ]]; then
    echo "❌ Could not find a matching binary for ${BIN_NAME}, OS: ${OS}, ARCH: ${ARCH}."
    exit 1
fi

# Construct download URL
DOWNLOAD_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$LATEST_TAG/$FILE_NAME"

# Download the binary
echo "⬇️ Downloading $FILE_NAME..."
curl -L "$DOWNLOAD_URL" -o "$BIN_NAME"

if [[ $? -ne 0 ]]; then
    echo "❌ Download failed. Check the repository or the asset name."
    exit 1
fi

# Make executable
chmod +x "$BIN_NAME"

echo "✅ Download complete! Run with: ./$BIN_NAME"