package application

import (
	"fmt"
	"hyperservice-control-plane/internal/mesh/model"
	"hyperservice-control-plane/internal/mesh/service"
	"hyperservice-control-plane/utils"
)

// MeshUpApplication handles the business logic for creating the mesh, invoking network setup, and starting the cluster.
func MeshUpApplication(cluster *[]model.ClusterNode) error {
	semaphoreFile := "/etc/hy-dp/env/HYPERSERVICE_MESH_INITIALIZING"

	// Set semaphore to "true" at the beginning
	if err := utils.UpdateSemaphore(semaphoreFile, "true"); err != nil {
		return utils.LogError("failed to update semaphore file", err)
	}
	defer utils.UpdateSemaphore(semaphoreFile, "false")

	// Call StartNetwork with the generated network name
	name := "hyperservice"
	err := service.StartNetwork(name)
	if err != nil {
		return utils.LogError("failed to setup network for mesh", err)
	}

	// Call StartCluster to start the K3D cluster after setting up the network
	err = service.StartCluster(name) 
	if err != nil {
		return utils.LogError("failed to start K3D cluster for mesh", err)
	}

	err = service.StartNodes(name, cluster)
	if err != nil {
		return utils.LogError("failed to start cluster nodes", err)
	}

	if err := service.StartMesh(name); err != nil {
		utils.LogError("Error: %s\n", err)
	} else {
		fmt.Println("Kuma installation completed successfully.")
	}

	return nil
}
