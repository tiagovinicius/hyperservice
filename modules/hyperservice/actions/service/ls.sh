# Function to list hyperservices

service_ls() {
  # Get the list of pods in the namespace
  pods=$(kubectl get pods -n "$HYPERSERVICE_NAMESPACE")

  # Check if there are any pods available
  if [ -z "$pods" ]; then
      echo "⚠️ No pods found in namespace '$HYPERSERVICE_NAMESPACE'"
      exit 1
  fi

  # Display the list of pods
  echo "📋 Listing all hyperservices pods"
  echo "===================================="
  echo "$pods"
  echo "===================================="

}
