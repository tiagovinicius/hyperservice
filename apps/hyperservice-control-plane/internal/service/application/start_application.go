package application

import (
	"fmt"
	"hyperservice-control-plane/internal/service/service"
)

// StartServiceService realiza o logging das variáveis passadas
func ServiceStartApplication(name, workdir string, podName string, policies []string) error {
	err := service.StartService(
		name,
		workdir,
		podName,
		policies,
	)
	if err != nil {
		return fmt.Errorf("ERROR: Failed to start service: %w", err)
	}

	return nil
}
