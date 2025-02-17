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

    local devcontainer_ip=$(hostname -i)

    # Realiza login no Docker Registry
    docker_login "$DOCKER_USERNAME" "$DOCKER_PASSWORD"
    
    create_k3d_cluster "$HYPERSERVICE_CLUSTER" "$devcontainer_ip"

    # Removendo o arquivo temporário após o uso
    rm -f "$containerd_config_file"

    # Get the server IP inside the "hy-bridge" network
    SERVER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3d-$HYPERSERVICE_CLUSTER-server-0)
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

    block_dockerhub "$HYPERSERVICE_CLUSTER"
    # import_images "$HYPERSERVICE_CLUSTER"

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

    echo "🔄 Enabling observability..."

    kumactl install observability | kubectl apply -f -

    setup_grafana_persistence

    # Wait for services to be alive
    wait_for_observability_liveness

    # Forwarding ports
    echo "🚀 Forwarding Prometheus (9090) and Grafana (3000)..."
    # Verificar e matar processos nas portas 9090 e 3000, se necessário
    kill_port_process 9090
    kill_port_process 3000
    nohup kubectl port-forward -n mesh-observability svc/prometheus-server 9090:80 &
    nohup kubectl port-forward -n mesh-observability svc/persistent-grafana 3000:80 &

    # Wait for services to be ready
    wait_for_observability_readiness

    echo "✅ Observability is ready!"

        echo "Applying policies..."
    # Define the POLICIES_DIR path
    POLICIES_DIR="$HYPERSERVICE_CURRENT_WORKSPACE_PATH/.hyperservice/policies"

    # Get all YAML files in the directory
    YAML_FILES=$(find "$POLICIES_DIR" -maxdepth 1 -type f -name "*.yml" | sort)

    # Ensure there is at least one policy file
    if [ -z "$YAML_FILES" ]; then
        echo "⚠️ No policy files found in $POLICIES_DIR"
        exit 1
    fi

    # Apply the mesh.yml policy first if it exists
    MESH_POLICY="$POLICIES_DIR/mesh.yml"
    if [ -f "$MESH_POLICY" ]; then
        echo "🚀 Applying mesh policy: $MESH_POLICY"
        echo "$(envsubst <"$MESH_POLICY")" | kubectl apply -f -
    fi

    # Apply remaining policies, excluding mesh.yml
    for FILE in $YAML_FILES; do
        if [ "$FILE" != "$MESH_POLICY" ]; then
            echo "📄 Applying policy: $FILE"
            echo "$(envsubst <"$FILE")" | kubectl apply -f -
        fi
    done

    echo "🔄 Building base images..."
    bash modules/hyperservice/mesh/dataplane/build-image.sh

    echo "🚀 DevContainer Setup Complete!"

}