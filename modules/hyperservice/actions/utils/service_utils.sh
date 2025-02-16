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
    for svc in prometheus-server persistent-grafana; do
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
setup_grafana_persistence() {
  # Definir variáveis principais
RELEASE_NAME="persistent-grafana"
NAMESPACE="mesh-observability"
NODE_NAME="k3d-hyperservice-cluster-server-0"
VALUES_FILE="grafana-values.yaml"

# Caminhos dos volumes no server-0
DATA_PATH="/var/lib/grafana/persistence"
LOGS_PATH="/var/log/grafana"
PROVISIONING_PATH="/etc/grafana/provisioning"

echo "🔄 Verificando se o Grafana já está instalado..."

# Remover o release se ele existir
if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
  echo "🛑 Removendo instalação existente do Grafana..."
  helm uninstall $RELEASE_NAME -n $NAMESPACE --no-hooks
  echo "⌛ Aguardando a remoção completa dos recursos..."
  sleep 5
fi

echo "🧹 Limpando possíveis resíduos do Grafana..."
kubectl delete all -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found
kubectl delete pvc -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found
kubectl delete secret -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found
kubectl delete configmap -n $NAMESPACE -l app.kubernetes.io/name=grafana --ignore-not-found

echo "📂 Criando diretórios no nó do K3d e corrigindo permissões..."
docker exec $NODE_NAME mkdir -p $DATA_PATH $LOGS_PATH $PROVISIONING_PATH
docker exec $NODE_NAME chmod -R 777 $DATA_PATH $LOGS_PATH $PROVISIONING_PATH

echo "⚙️ Criando arquivo de configuração do Helm ($VALUES_FILE)..."
cat <<EOF > $VALUES_FILE
persistence:
  enabled: false
  existingClaim: ""

grafana.ini:
  paths:
    data: /var/lib/grafana/persistence
    logs: $LOGS_PATH
    provisioning: $PROVISIONING_PATH
    plugins: /var/lib/grafana/persistence/plugins

extraVolumes:
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

extraVolumeMounts:
  - name: grafana-storage
    mountPath: /var/lib/grafana/persistence
  - name: logs-grafana
    mountPath: $LOGS_PATH
  - name: provisioning-grafana
    mountPath: $PROVISIONING_PATH
EOF

echo "🚀 Instalando o Grafana usando Helm..."
helm install "$RELEASE_NAME" grafana/grafana -n "$NAMESPACE" -f "$VALUES_FILE"

}

# ---------------------------
# 🎯 Criando o cluster k3d e conectando ao Registry
create_k3d_cluster() {
    local cluster_name=$1
    local ip=$2

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
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume /etc/hyperservice/data/grafana/data:/var/lib/grafana/persistence \
    --volume /etc/hyperservice/data/grafana/provisioning:/etc/grafana/provisioning \
    --volume /etc/hyperservice/log/grafana:/var/log/grafana

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

    # Verify if the cluster exists
    if ! k3d cluster list | grep -q "$cluster_name"; then
        echo "❌ Cluster $cluster_name not found! Please check with 'k3d cluster list'."
        exit 1
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
    
    for image in $images; do
      echo "📦 Importing $image..."
      k3d image import "$image"  --cluster "$cluster_name"
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

