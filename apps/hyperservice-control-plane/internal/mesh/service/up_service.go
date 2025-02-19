package service

import (
	"hyperservice-control-plane/utils" 
	"hyperservice-control-plane/internal/mesh/service/utils"
)

// MeshUpService handles the business logic for creating the mesh and invoking network setup.
func MeshUpService() error {
	// Call StartNetwork with the generated network name
	name := "hyperservice"
	err := service.StartNetwork(name)
	if err != nil {
		return utils.LogError("failed to setup network for mesh", err) 
	}
	return nil
}