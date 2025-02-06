#!/bin/bash
mesh_dp_deploy() {
    pushd "$HYPERSERVICE_APP_PATH" >/dev/null || {
        echo "Failed to navigate to $HYPERSERVICE_APP_PATH"
        exit 1
    }

    git config --global safe.directory '*'

    export CONTAINER_IP=$(hostname -i)

    echo "Waiting control plane to be running"
    elapsed=0
    sleep_interval=1
    try_deploy_kuma() {
        set -o pipefail
        echo "Accessing control plane..."
        CONTROL_PLANE_IP=$(cat $HYPERSERVICE_SHARED_ENVIRONMENT/CONTROL_PLANE_IP 2>/dev/null || true)
        CONTROL_PLANE_ADMIN_USER_TOKEN=$(cat $HYPERSERVICE_SHARED_ENVIRONMENT/CONTROL_PLANE_ADMIN_USER_TOKEN 2>/dev/null || true)
        temp_file=$(mktemp)
        kumactl config control-planes add \
            --name=default \
            --address=http://$CONTROL_PLANE_IP:5681 \
            --auth-type=tokens \
            --auth-conf token=${CONTROL_PLANE_ADMIN_USER_TOKEN} 2>&1 >"$temp_file"
        [ $? -ne 0 ] || grep -Eq "could not connect" "$temp_file" && {
            echo "Error executing kumactl"
            cat "$temp_file"
            rm "$temp_file"
            return 1
        }
        echo "Kumactl executed successfully"
        rm "$temp_file"

        echo "Control plane is running"

        echo "Applying policies"
        POLICIES_DIR=".hyperservice/policies"
        for FILE in $(ls "$POLICIES_DIR"/*.yml | sort); do
            echo "Applying file $FILE"
            echo "$(envsubst <"$FILE")" | kumactl apply -f -
        done

        echo "Setting up dataplane"
        kumactl generate dataplane-token --tag kuma.io/service=$DATAPLANE_NAME --valid-for=720h >/.token
        useradd -u 5678 -U kuma-dp
        kumactl install transparent-proxy \
            --kuma-dp-user kuma-dp \
            --redirect-dns \
            --exclude-inbound-ports 22
        runuser -u kuma-dp -- \
            kuma-dp run \
            --cp-address https://$CONTROL_PLANE_IP:5678 \
            --dataplane-token-file=/.token \
            --dataplane="$(envsubst <.hyperservice/dataplane.yml)" \
            2>&1 | tee logs/dataplane-logs.txt &

        return 0
    }
    while ! try_deploy_kuma; do
        echo "Waiting for control plane to be running..."
        sleep $sleep_interval
        elapsed=$((elapsed + sleep_interval))

        if [ $sleep_interval -lt 60 ]; then
            sleep_interval=$((sleep_interval * 2))
            if [ $sleep_interval -gt 60 ]; then
                sleep_interval=60
            fi
        fi
    done

    echo "Creating directories"
    mkdir -p logs

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
