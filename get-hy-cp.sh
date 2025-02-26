#!/bin/bash

# GitHub repository details
REPO_OWNER="tiagovinicius"
REPO_NAME="hyperservice"
BIN_NAME="hy-cp"

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
FILE_NAME=$(echo "$ASSET_LIST" | grep -E "^${BIN_NAME}-[0-9]+\.[0-9]+\.[0-9]+-${OS}-${ARCH}\.tar$")

if [[ -z "$FILE_NAME" ]]; then
    echo "❌ Could not find a matching package for ${BIN_NAME}, OS: ${OS}, ARCH: ${ARCH}."
    exit 1
fi

# Construct download URL
DOWNLOAD_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$LATEST_TAG/$FILE_NAME"

# Download the tar package
echo "⬇️ Downloading $FILE_NAME..."
curl -L "$DOWNLOAD_URL" -o "$FILE_NAME"

if [[ $? -ne 0 ]]; then
    echo "❌ Download failed. Check the repository or the asset name."
    exit 1
fi

# Create a temporary directory for extraction
TMP_DIR="/tmp/hy-cp"
mkdir -p "$TMP_DIR"

# Extract the package
echo "📦 Extracting $FILE_NAME..."
tar -xvf "$FILE_NAME" -C "$TMP_DIR"

# Move hy-cp binary to /usr/local/bin
if [[ -f "$TMP_DIR/hy-cp" ]]; then
    echo "🚀 Installing $BIN_NAME..."
    cp "$TMP_DIR/hy-cp" /usr/local/bin/
    chmod +x /usr/local/bin/hy-cp
else
    echo "❌ Error: hy-cp binary not found in the package."
    exit 1
fi

# Ensure /opt/hy-cp exists
mkdir -p /opt/hy-cp

# Move config files to /opt/hy-cp if they exist
if [[ -d "$TMP_DIR/config" && "$(ls -A $TMP_DIR/config)" ]]; then
    echo "📂 Moving config files..."
    cp -r "$TMP_DIR/config/." /opt/hy-cp/
else
    echo "⚠️ No config files found in the package."
fi

# Cleanup
echo "🧹 Cleaning up..."
rm -rf "$TMP_DIR" "$FILE_NAME"

echo "✅ Installation complete! Run with: hy-cp"