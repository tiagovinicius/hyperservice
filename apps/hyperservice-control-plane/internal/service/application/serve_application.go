package application

import (
	"fmt"
	"hyperservice-control-plane/internal/service/service"
)

// ServeServiceService realiza o logging das variáveis passadas
func ServiceServeApplication(name, imageName string, podName string, policies []string, envVars map[string]string) error {
	err := service.ServeService(
		name,
		imageName,
		podName,
		policies,
		envVars,
	)
	if err != nil {
		return fmt.Errorf("ERROR: Failed to serve service: %w", err)
	}

	return nil
}
