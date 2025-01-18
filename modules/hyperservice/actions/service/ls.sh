# Function to list hyperservices

service_ls() {
  echo "Listing all hyperservices:"

  # List all hyperservices with specific details
  docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Ports}}"

}
