#!/bin/bash


mesh_up() {
    set -e

    echo "🚀 Starting DevContainer Setup..."

    # Ensure Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo "❌ ERROR: Docker is not running! Please check your setup."
        exit 1
    fi

    # Create a custom Docker network if it does not already exist
    if ! docker network ls | grep -q hy-bridge; then
        echo "🔧 Creating Docker network 'hy-bridge'..."
        docker network create --subnet=192.168.1.0/24 hy-bridge
    else
        echo "✅ Docker network 'hy-bridge' already exists!"
    fi

    # Check if K3d is installed correctly
    if ! command -v k3d &> /dev/null; then
        echo "❌ ERROR: K3d is not installed!"
        exit 1
    fi

    # Check if Kubectl is installed correctly
    if ! command -v kubectl &> /dev/null; then
        echo "❌ ERROR: Kubectl is not installed!"
        exit 1
    fi

    # Check if Kuma is installed correctly
    if ! command -v kumactl &> /dev/null; then
        echo "❌ ERROR: Kuma is not installed!"
        exit 1
    fi

    # Remove old clusters to avoid conflicts
    EXISTING_CLUSTERS=$(k3d cluster list -o json | jq -r '.[].name')
    if [ -n "$EXISTING_CLUSTERS" ]; then
        echo "⚠️ Found existing clusters: $EXISTING_CLUSTERS"
        for CLUSTER in $EXISTING_CLUSTERS; do
            echo "🛑 Deleting cluster '$CLUSTER'..."
            k3d cluster delete "$CLUSTER"
        done
        echo "✅ All existing clusters removed!"
    fi

echo "HYPERSERVICE_BIN_PATH=$HYPERSERVICE_BIN_PATH"
echo "HYPERSERVICE_WORKSPACE_PATH=$HYPERSERVICE_WORKSPACE_PATH"
    # Create K3d cluster inside the "hy-bridge" network
    echo "⏳ Creating K3s cluster 'hy-cluster'..."
    k3d cluster create hy-cluster \
    --servers 1 \
    --api-port 6443 \
    --network hy-bridge \
    --volume "$HYPERSERVICE_BIN_PATH:$HYPERSERVICE_BIN_PATH" \
    --volume "$HYPERSERVICE_WORKSPACE_PATH:$HYPERSERVICE_WORKSPACE_PATH" \
    --volume /var/run/docker.sock:/var/run/docker.sock

    # Get the server IP inside the "hy-bridge" network
    SERVER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3d-hy-cluster-server-0)
    echo "🌍 K3s Server IP: $SERVER_IP"

    # Update kubeconfig to use the correct IP
    sed -i "s/0.0.0.0/$SERVER_IP/g" ~/.kube/config

    # Wait for Kubernetes API to be ready
    echo "⏳ Waiting for Kubernetes API..."
    for i in {1..15}; do
        if kubectl cluster-info > /dev/null 2>&1; then
            echo "✅ Kubernetes API is ready!"
            break
        fi
        echo "🔄 Attempt $i/15: API not ready, retrying..."
        sleep 5
    done

    # Test connection with Kubernetes
    kubectl get nodes || {
        echo "❌ ERROR: Kubernetes nodes are not accessible!"
        exit 1
    }

    echo "📦 Adding Helm repository for Kuma..."
    helm repo add kuma https://kumahq.github.io/charts
    helm repo update

    echo "🚀 Installing Kuma..."

    echo "⚙️ Creating 'kuma-system' namespace..."
    kubectl create namespace kuma-system


    echo "⚙️ Creating '$HYPERSERVICE_NAMESPACE' namespace..."
    kubectl create namespace $HYPERSERVICE_NAMESPACE
    kubectl label namespace $HYPERSERVICE_NAMESPACE kuma.io/sidecar-injection=enabled

    echo "🔄 Installing Kuma in namespace 'kuma-system'..."
    helm install --namespace kuma-system kuma kuma/kuma
 

    wait_for_control_plane_liveness

    echo "🚀 Forwarding Kuma Control Plane por 5681..."
    nohup kubectl port-forward -n kuma-system svc/kuma-control-plane 5681:5681 &


    wait_for_control_plane_readiness

    echo "✅ Kuma Control Plane is responsive"

    echo "✅ Kuma Control Plane successfully installed!"

    echo "Applying policies..."
    # Define the POLICIES_DIR path
    POLICIES_DIR="$HYPERSERVICE_CURRENT_WORKSPACE_PATH/.hyperservice/policies"

    # Check if the directory exists before listing files
    if [ -d "$POLICIES_DIR" ]; then
        # Get all .yml files in the directory
        YAML_FILES=$(find "$POLICIES_DIR" -maxdepth 1 -type f -name "*.yml" | sort)

        # Check if there are YAML files before iterating
        if [ -n "$YAML_FILES" ]; then
            for FILE in $YAML_FILES; do
                echo "📄 Applying file: $FILE"
                echo "$(envsubst <"$FILE")" | kubectl apply -f -
            done
        else
            echo "⚠️ No policy files found in $POLICIES_DIR"
        fi
    else
        echo "⚠️ A policies directory does not exist: $POLICIES_DIR"
    fi

    echo "🔄 Building base images..."
    bash modules/hyperservice/mesh/dataplane/build-image.sh

    echo "🚀 DevContainer Setup Complete!"

}