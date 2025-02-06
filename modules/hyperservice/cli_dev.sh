#!/bin/bash

HYPERSERVICE_REAL_BIN_PATH="$(realpath "$(readlink -f "${BASH_SOURCE[0]}")" | xargs dirname)"
HYPERSERVICE_BIN_PATH="/usr/local/bin/hyperservice-bin"

rm -rf "$HYPERSERVICE_BIN_PATH"/*

mkdir -p "$HYPERSERVICE_BIN_PATH"
cp -r "$HYPERSERVICE_REAL_BIN_PATH"/* "$HYPERSERVICE_BIN_PATH"

chmod +x "$HYPERSERVICE_REAL_BIN_PATH/cli.sh"
bash "$HYPERSERVICE_REAL_BIN_PATH/cli.sh" "$@"
