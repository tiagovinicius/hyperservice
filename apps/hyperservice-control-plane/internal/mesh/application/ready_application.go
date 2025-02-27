package application

import (
	"fmt"
	"hyperservice-control-plane/internal/mesh/service"
	"hyperservice-control-plane/utils"
)

func MeshReadyApplication() error {
	semaphoreFile := "/etc/hy-dp/env/HYPERSERVICE_MESH_INITIALIZING"

	status, err := utils.CheckSemaphore(semaphoreFile)
	if err != nil {
		return err
	}

	if status == "true" {
		return fmt.Errorf("❌ ERROR: Mesh initialization is in progress")
	}

	return service.GetClusterReadinessService("hyperservice")
}
