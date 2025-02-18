#!/bin/bash
mesh_dp_deploy() {
    pushd "$HYPERSERVICE_APP_PATH" >/dev/null || {
        echo "Failed to navigate to $HYPERSERVICE_APP_PATH"
        exit 1
    }

    echo "Creating directories"
    mkdir -p logs

    echo "Setting up environment metrics collect"
    sudo /etc/init.d/collectd stop
    sudo collectd -C $HYPERSERVICE_BIN_PATH/common-services/observability/config/collectd.conf

    echo "Starting service $SERVICE_NAME"
    # moon $SERVICE_NAME:dev \
    #     2>&1 | tee logs/app-logs.txt

    if [ -x "src/entrypoint.sh" ]; then
        echo "Running src/entrypoint.sh..."
        exec src/entrypoint.sh
    elif npm run dev --dry-run &>/dev/null; then
        echo "Running npm run dev..."
        npm run dev
    else
        echo "No valid option found. Sleeping indefinitely..."
        exec sleep infinity
    fi

    popd >/dev/null
}
