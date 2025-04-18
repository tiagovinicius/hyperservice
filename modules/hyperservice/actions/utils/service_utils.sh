resolve_workdir() {
  local service_name="$1"
  local workdir="$2"

  if [[ -z "$workdir" ]]; then
    local json_output
    json_output=$(moon query projects --json)
    workdir=$(echo "$json_output" | jq -r --arg service_name "$service_name" '.projects[] | select(.id == $service_name) | .source')
  fi

  if [[ -z "$workdir" ]]; then
    echo "Error: Unable to determine workdir for service: $service_name"
    return 1
  fi

  echo "$workdir"
}

run_service() {
  local service_name="$1"
  local workdir="$2"
  local image="$3"
  local node_name="${4:-$service_name}" # Default to service_name if node_name is not provided
  shift 4
  local additional_args=("$@")

  wait_for_control_plane_readiness

  HYPERSERVICE_IMAGE="$image" \
  SERVICE_NAME="$service_name" \
  HYPERSERVICE_BIN_PATH="$HYPERSERVICE_BIN_PATH" \
  HYPERSERVICE_WORKSPACE_PATH="$HYPERSERVICE_WORKSPACE_PATH" \
  HYPERSERVICE_SHARED_ENVIRONMENT="$HYPERSERVICE_SHARED_ENVIRONMENT" \
  HYPERSERVICE_NAMESPACE="$HYPERSERVICE_NAMESPACE" \
  HYPERSERVICE_APP_PATH="$workdir" \
  HYPERSERVICE_DATAPLANE_NAME="$node_name" \
  K8S_NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')" \
  envsubst <"$HYPERSERVICE_BIN_PATH/actions/service/start.yaml" | kubectl apply -f -

  echo "Applying policies..."
  # Define the POLICIES_DIR path
  POLICIES_DIR="$HYPERSERVICE_CURRENT_WORKSPACE_PATH/$workdir/.hyperservice/policies"

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
}

wait_for_control_plane_liveness() {
  echo "⏳ Waiting for Kuma Control Plane pod to be in Running state..."
  until kubectl get pods -n kuma-system -l app=kuma-control-plane -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; do
      echo "🔄 Kuma Control Plane pod is not ready yet. Retrying in 5s..."
      sleep 5
  done

  echo "✅ Kuma Control Plane pod is now Running!"

  echo "⏳ Waiting for Kuma Control Plane service to have active endpoints..."
  until kubectl get endpoints -n kuma-system kuma-control-plane -o jsonpath="{.subsets}" | grep -q "addresses"; do
      echo "🔄 Kuma Control Plane service does not have active endpoints yet. Retrying in 5s..."
      sleep 5
  done

  echo "✅ Kuma Control Plane service is now ready!"
}

wait_for_control_plane_readiness () {
  # Wait for the Kuma Control Plane to be responsive on port 5681
  until curl -s "http://localhost:5681" >/dev/null; do
      echo "🔄 Waiting for Kuma Control Plane (http://locahost:5681) to respond..."
      sleep 5
  done
}


# Function to check if all observability pods are running
wait_for_observability_liveness() {
    echo "⏳ Waiting for Observability pods to be in Running state..."

    for pod in $(kubectl get pods -n mesh-observability -o jsonpath="{.items[*].metadata.name}"); do
        until kubectl get pod -n mesh-observability "$pod" -o jsonpath="{.status.phase}" 2>/dev/null | grep -q "Running"; do
            echo "🔄 Pod $pod is not ready yet. Retrying in 5s..."
            sleep 5
        done
        echo "✅ Pod $pod is Running!"
    done

    echo "⏳ Waiting for Observability services to have active endpoints..."
    for svc in prometheus grafana; do
        until kubectl get endpoints -n mesh-observability "$svc" -o jsonpath="{.subsets}" 2>/dev/null | grep -q "addresses"; do
            echo "🔄 Service $svc does not have active endpoints yet. Retrying in 5s..."
            sleep 5
        done
        echo "✅ Service $svc is now ready!"
    done
}

# Function to check if observability services are responsive
wait_for_observability_readiness() {
    echo "⏳ Checking if Observability services are responding..."

    # Check Prometheus
    until curl -s "http://localhost:9090" >/dev/null; do
        echo "🔄 Waiting for Prometheus (http://localhost:9090) to respond..."
        sleep 5
    done
    echo "✅ Prometheus is responsive!"

    # Check Grafana
    until curl -s "http://localhost:3000" >/dev/null; do
        echo "🔄 Waiting for Grafana (http://localhost:3000) to respond..."
        sleep 5
    done
    echo "✅ Grafana is responsive!"
}

# 🚀 Function to configure persistent storage for Kuma's Grafana using the default Grafana path
setup_grafana() {
# Definir variáveis principais
RELEASE_NAME="grafana"
NAMESPACE="mesh-observability"
NODE_NAME="k3d-hyperservice-cluster-server-0"
VALUES_FILE="grafana-values.yaml"

# Caminho do volume no server-0 e no pod
DATA_PATH="/var/lib/grafana"  # Volume path for both devcontainer (server-0) and pod
LOGS_PATH="/var/log/grafana"
PROVISIONING_PATH="/etc/grafana/provisioning"

echo "🔄 Verificando se o Grafana já está instalado..."

# Remover o release se ele existir
kubectl delete deployment grafana -n $NAMESPACE --ignore-not-found
kubectl delete service grafana -n $NAMESPACE --ignore-not-found

echo "🧹 Limpando possíveis resíduos do Grafana..."
kubectl delete all -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found
kubectl delete pvc -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found
kubectl delete secret -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found
kubectl delete configmap -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found

echo "📂 Criando diretórios no nó do K3d e corrigindo permissões..."
docker exec $NODE_NAME mkdir -p $DATA_PATH $LOGS_PATH $PROVISIONING_PATH
docker exec $NODE_NAME chmod -R 777 $DATA_PATH $LOGS_PATH $PROVISIONING_PATH

# Criando o Manifesto do Service e Deployment para o Grafana com o volume do server-0 para persistência
echo "⚙️ Criando Manifesto do Grafana (Service e Deployment)..."
cat <<EOF > grafana-manifest.yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
    kuma.io/mesh: default
spec:
  type: ClusterIP
  ports:
    - name: service
      port: 80
      protocol: TCP
      targetPort: 3000
  selector:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
    kuma.io/mesh: default
  annotations:
    kuma.io/sidecar-injection: enabled
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: grafana
      app.kubernetes.io/name: grafana
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: grafana
        app.kubernetes.io/name: grafana
        kuma.io/mesh: default
        kuma.io/sidecar-injection: enabled
    spec:
      initContainers:
      - name: init-create-grafana-dir
        image: busybox
        command: ["sh", "-c", "mkdir -p /var/lib/grafana"]
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana   # Mount volume to /var/lib/grafana
      containers:
      - name: grafana
        image: grafana/grafana:11.6.0
        ports:
        - containerPort: 3000
          name: grafana
        - containerPort: 9094
          name: gossip-tcp
          protocol: TCP
        - containerPort: 9094
          name: gossip-udp
          protocol: UDP
        - containerPort: 6060
          name: profiling
          protocol: TCP
        env:
        - name: GF_PATHS_DATA
          value: /var/lib/grafana   # Ensures Grafana uses /var/lib/grafana for data
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana   # Mount persistence directory at /var/lib/grafana
        - name: logs-grafana
          mountPath: /var/log/grafana
        - name: provisioning-grafana
          mountPath: /etc/grafana/provisioning
      volumes:
      - name: grafana-storage
        hostPath:
          path: $DATA_PATH
          type: DirectoryOrCreate
      - name: logs-grafana
        hostPath:
          path: $LOGS_PATH
          type: DirectoryOrCreate
      - name: provisioning-grafana
        hostPath:
          path: $PROVISIONING_PATH
          type: DirectoryOrCreate
EOF

# Aplicando o Manifesto do Grafana
echo "🚀 Aplicando Manifesto do Grafana..."
kubectl apply -f grafana-manifest.yaml -n $NAMESPACE

# Triggering a rolling update to apply the label and restart pods
echo "🔄 Triggering a rolling update for the deployment..."
kubectl rollout restart deployment grafana -n mesh-observability
}


# ---------------------------
# 🎯 Criando o cluster k3d e conectando ao Registry
create_k3d_cluster() {
    local cluster_name=$1

    # Remove old clusters to avoid conflicts
    existing_cluster=$(k3d cluster list -o json | jq -r '.[].name')
    if [ -n "$existing_cluster" ]; then
        echo "⚠️ Found existing clusters: $existing_cluster"
        for cluster in $existing_cluster; do
            echo "🛑 Deleting cluster '$cluster'..."
            k3d cluster delete "$cluster"
        done
        echo "✅ All existing clusters removed!"
    fi

    # Create K3d cluster inside the "hy-bridge" network
    echo "⏳ Creating K3s cluster '$cluster_name'..."
    k3d cluster create $cluster_name \
    --servers 1 \
    --api-port 6443 \
    --network hy-bridge \
    --volume "$HYPERSERVICE_BIN_PATH:$HYPERSERVICE_BIN_PATH" \
    --volume "$HYPERSERVICE_WORKSPACE_PATH:$HYPERSERVICE_WORKSPACE_PATH" \
    --volume "$HYPERSERVICE_SHARED_CONFIG:$HYPERSERVICE_SHARED_CONFIG" \
    --volume "$HYPERSERVICE_GRAFANA_DATA_VOLUME:/var/lib/grafana" \
    --volume /var/run/docker.sock:/var/run/docker.sock

    echo "✅ Cluster k3d '${cluster_name}' criado com sucesso!"
}

# ---------------------------
# 🎯 Perform Docker login **ONLY** for Docker Hub (docker.io)
docker_login() {
    local username=$1
    local password=$2

    echo "🔑 Logging into Docker Hub (docker.io)..."

    if echo "$password" | docker login docker.io -u "$username" --password-stdin &>/dev/null; then
        echo "✅ Successfully logged in to Docker Hub!"
    else
        echo "❌ Failed to authenticate with Docker Hub! Check your credentials."
    fi
}

# ---------------------------
# 🎯 Reiniciando o cluster k3d para aplicar configurações
restart_k3d_cluster() {
    local cluster_name=$1
    echo "🔄 Reiniciando cluster k3d '${cluster_name}'..."
    k3d cluster stop "$cluster_name"
    k3d cluster start "$cluster_name"
    echo "✅ Cluster k3d '${cluster_name}' reiniciado com sucesso!"
}

# Script to import all Docker images from the local cache to k3d cluster
# ✅ It checks if the image is already present in the cluster before importing.
import_images() {
    local cluster_name="$1"
    local images_cache_file="$HYPERSERVICE_CURRENT_WORKSPACE_PATH/.hyperservice/images-cache.yml"

    # Verify if the cluster exists
    if ! k3d cluster list | grep -q "$cluster_name"; then
        echo "❌ Cluster $cluster_name not found! Please check with 'k3d cluster list'."
        exit 1
    fi

    # Verify if the images cache YAML file exists
    if [[ ! -f "$images_cache_file" ]]; then
        echo "❌ $images_cache_file not found! Please check the path."
        exit 0
    fi

    # Check if the images cache YAML file exists, but don't exit if it doesn't
    if [[ ! -f "$images_cache_file" ]]; then
        echo "⚠️ $images_cache_file not found! Continuing without the images cache file."
        images_list=""
    else
        # Extract image list from YAML file if it exists
        local image_list_from_yaml
        image_list_from_yaml=$(yq -r '.images // [] | .[]' "$images_cache_file" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        images_list="$image_list_from_yaml"
    fi

    echo "🔍 Listing all local Docker images..."
    
    # Get all Docker images (ignoring <none>:<none> images)
    local images
    images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>")

    if [[ -z "$images" ]]; then
        echo "❌ No valid images found in local Docker cache."
        exit 1
    fi

    echo "🚀 Checking and importing images into k3d cluster: $cluster_name..."

    # If there's no image list from YAML, we import all local images
    if [[ -z "$images_list" ]]; then
        echo "⚠️ No image list found from YAML. Importing all local images."
        image_list_from_yaml="$images"
    else
        # Loop through all images in the YAML file and check if they exist locally
        for image in $images_list; do
            if echo "$images" | grep -q "$image"; then
                echo "📦 $image already in local cache..."
            else
                echo "🔄 Downloading $image from the registry..."
                docker pull "$image"
            fi
        done
    fi

    # Import the images into the k3d cluster
    for image in $image_list_from_yaml; do
        echo "📦 Importing $image into cluster $cluster_name..."
        k3d image import "$image" --cluster "$cluster_name"
    done

    echo "🎉 All necessary images have been imported successfully!"
}

# 🔒 Prevents pulling images from Docker Hub inside k3d
block_dockerhub() {
    local cluster_name="$1"

    echo "📌 Creating CoreDNS configuration to block docker.io..."

    # Create a CoreDNS ConfigMap to block docker.io
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  custom.server: |
    docker.io {
        hosts {
            127.0.0.1 docker.io
            fallthrough
        }
    }
EOF

    echo "✅ CoreDNS configuration created. Restarting CoreDNS to apply changes..."

    # Restart CoreDNS to apply the new configuration
    kubectl rollout restart deployment coredns -n kube-system

    echo "🚫 Access to docker.io is now blocked inside K3d!"
}

# Função para matar processos que estão usando a porta específica
kill_port_process() {
  PORT=$1
  echo "🔄 Checking if port $PORT is in use..."
  # Verifica se a porta está sendo usada, e se sim, mata o processo
  PID=$(ss -ltnp | grep ":$PORT" | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2)
  
  if [ -n "$PID" ]; then
    echo "🚨 Port $PORT is in use. Killing the process with PID $PID..."
    kill -9 $PID
  else
    echo "✅ Port $PORT is not in use."
  fi
}

