#!/bin/bash

wait_shared_enviroment () {
    # Retrieve the correct IP of the Control Plane within the cluster
    CONTROL_PLANE_IP=$(kubectl get svc -n kuma-system kuma-control-plane -o jsonpath='{.spec.clusterIP}')
    if [ -z "$CONTROL_PLANE_IP" ]; then
        echo "❌ ERROR: Unable to retrieve CONTROL_PLANE_IP"
        exit 1
    fi

    # Wait for the Kuma Control Plane to be responsive on port 5681
    until curl -s "http://localhost:5681" >/dev/null; do
        echo "🔄 Waiting for Kuma Control Plane ($CONTROL_PLANE_IP:5681 -> http://locahost:5681) to respond..."
        sleep 5
    done
    echo "✅ Kuma Control Plane is responsive"

    # Secure concurrent writes with flock
    flock /etc/hyperservice/shared/environment/CONTROL_PLANE_IP \
    -c "echo $CONTROL_PLANE_IP > /etc/hyperservice/shared/environment/CONTROL_PLANE_IP"

    echo "✅ Stored CONTROL_PLANE_IP: $CONTROL_PLANE_IP"

    # Retrieve the admin user token from the Kuma Control Plane
    CONTROL_PLANE_ADMIN_USER_TOKEN=$(curl -s http://$CONTROL_PLANE_IP:5681/global-secrets/admin-user-token | jq -r .data | base64 -d)
    if [ -z "$CONTROL_PLANE_ADMIN_USER_TOKEN" ]; then
        echo "❌ ERROR: Failed to retrieve CONTROL_PLANE_ADMIN_USER_TOKEN"
        exit 1
    fi

    # Secure concurrent writes with flock
    flock /etc/hyperservice/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN \
    -c "echo $CONTROL_PLANE_ADMIN_USER_TOKEN > /etc/hyperservice/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN"

    echo "✅ Stored CONTROL_PLANE_ADMIN_USER_TOKEN"

    echo "✅ Kuma Control Plane successfully installed!"

    echo "🚀 DevContainer Setup Complete!"
}


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

    # Create K3d cluster inside the "hy-bridge" network
    echo "⏳ Creating K3s cluster 'hy-cluster'..."
    k3d cluster create hy-cluster \
    --servers 1 \
    --api-port 6443 \
    --network hy-bridge

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

    echo "🚀 Installing Kuma Control Plane in namespace 'kuma-system'..."

    # Create kuma-system namespace if it doesn't exist
    if ! kubectl get namespace kuma-system >/dev/null 2>&1; then
        echo "⚙️ Namespace 'kuma-system' not found. Creating it..."
        kubectl create namespace kuma-system
    fi

    if helm list -n kuma-system | grep -q "kuma"; then
        echo "🔄 Kuma is already installed. Upgrading..."
        helm upgrade --namespace kuma-system kuma kuma/kuma
    else
        echo "🚀 Installing Kuma Control Plane in namespace 'kuma-system'..."
        helm install --namespace kuma-system kuma kuma/kuma
    fi

    echo "⏳ Waiting for Kuma Control Plane to be ready..."
    until kubectl get svc -n kuma-system kuma-control-plane &>/dev/null; do
        echo "🔄 Kuma Control Plane service not found. Retrying in 5s..."
        sleep 5
    done

    wait_shared_enviroment

    echo "🚀 Forwarding Kuma Control Plane por 5681..."
    nohup kubectl port-forward -n kuma-system svc/kuma-control-plane 5681:5681  > port-forward.log 2>&1 &

}