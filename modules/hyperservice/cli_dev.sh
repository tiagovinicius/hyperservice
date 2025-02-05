#!/bin/bash

HYPERSERVICE_REAL_BIN_PATH="$(realpath "$(readlink -f "${BASH_SOURCE[0]}")" | xargs dirname)"
HYPERSERVICE_BIN_PATH="/usr/local/bin/hyperservice-bin"

echo "Cleaning up the old directory at $HYPERSERVICE_BIN_PATH..."
rm -rf "$HYPERSERVICE_BIN_PATH"

echo "Copying $HYPERSERVICE_REAL_BIN_PATH to $HYPERSERVICE_BIN_PATH..."
cp -r "$HYPERSERVICE_REAL_BIN_PATH" "$HYPERSERVICE_BIN_PATH"

echo "Running cli.sh..."
chmod +x "$HYPERSERVICE_REAL_BIN_PATH/cli.sh"
bash "$HYPERSERVICE_REAL_BIN_PATH/cli.sh" "$@"
