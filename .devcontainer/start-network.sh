if [ -z "$(docker network ls --filter name=^service-mesh$ --format '{{.Name}}')" ]; then
    echo "Network 'service-mesh' not found. Creating the network..."
    docker network create service-mesh
    echo "Network 'service-mesh' created successfully."
    else
    echo "The network 'service-mesh' already exists."
fi