package application

import (
	"fmt"

	"hyperservice-control-plane/internal/mesh/service"
	"hyperservice-control-plane/utils"
)

// MeshUpApplication handles the business logic for creating the mesh, invoking network setup, and starting the cluster.
func MeshUpApplication() error {
	// Call StartNetwork with the generated network name
	name := "hyperservice"
	err := service.StartNetwork(name)
	if err != nil {
		return utils.LogError("failed to setup network for mesh", err)
	}

	// Call StartCluster to start the K3D cluster after setting up the network
	err = service.StartCluster(name) // Using 'name' for the cluster name as well
	if err != nil {
		return utils.LogError("failed to start K3D cluster for mesh", err)
	}

	if err := service.StartMesh(name); err != nil {
		utils.LogError("Error: %s\n", err)
	} else {
		fmt.Println("Kuma installation completed successfully.")
	}

	return nil
}
