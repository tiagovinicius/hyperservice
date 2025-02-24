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

# Get latest release tag
echo "🔍 Fetching latest release..."
LATEST_TAG=$(curl -sL "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest" | grep '"tag_name":' | awk -F'"' '{print $4}')

if [[ -z "$LATEST_TAG" ]]; then
    echo "❌ Failed to get the latest release tag."
    exit 1
fi

echo "📦 Latest release: $LATEST_TAG"

# Construct download URL
FILE_NAME="${BIN_NAME}-${LATEST_TAG}-${OS}-${ARCH}"
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