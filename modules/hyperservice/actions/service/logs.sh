# Function to view logs of hyperservice

service_logs() {
  local name="$1"

  echo "Viewing logs for hyperservice: $name"

  # View the logs of the hyperservice
  # Get the list of pods in the namespace
  pods=$(kubectl get pods -l "app=$name" -n "$HYPERSERVICE_NAMESPACE" --no-headers -o custom-columns=":metadata.name")

  # Check if there are any pods available
  if [ -z "$pods" ]; then
      echo "⚠️ No pods found in for app '$name'"
      exit 1
  fi

  # Iterate over the pods and display their logs
  for pod in $pods; do
      echo "📜 Logs for pod: $pod"
      echo "----------------------------------"
      kubectl logs -n "$HYPERSERVICE_NAMESPACE" "$pod"
      echo "=================================="
  done
}
