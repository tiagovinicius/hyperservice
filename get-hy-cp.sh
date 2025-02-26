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

# Extract the package
echo "📦 Extracting $FILE_NAME..."
tar -xvf "$FILE_NAME" -C /tmp/

# Move hy-cp binary to /usr/local/bin
echo "🚀 Installing $BIN_NAME..."
mv -f /tmp/hy-cp /usr/local/bin/
chmod +x /usr/local/bin/hy-cp

# Ensure /etc/hy-cp exists
mkdir -p /etc/hy-cp
mkdir -p /etc/collectd

# Move config files to /etc/hy-cp
echo "📂 Moving config files..."
mv -f /tmp/config/* /etc/hy-cp/
mv -f /etc/config/collectd.conf /etc/collectd/collectd.conf

# Cleanup
echo "🧹 Cleaning up..."
rm -rf /tmp/hy-cp /tmp/config "$FILE_NAME"

echo "✅ Installation complete! Run with: hy-cp"
