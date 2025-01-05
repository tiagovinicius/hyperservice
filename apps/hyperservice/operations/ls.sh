# Function to list hyperservices

ls_hyperservices() {
  echo "Listing all hyperservices:"

  # List all hyperservices with specific details
  docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Ports}}"

}
