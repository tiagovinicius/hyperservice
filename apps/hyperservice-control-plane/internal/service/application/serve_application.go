package application

import (
	"fmt"
	"hyperservice-control-plane/internal/service/service"
)

// ServeServiceService realiza o logging das variáveis passadas
func ServiceServeApplication(name string, cluster []string, imageName string, policies []string, envVars map[string]string, build bool, workdir string) error {
	if build {
		baseImageName := imageName
		imageName = fmt.Sprintf("hyperservice-svc-%s-image:latest", name)
		err := service.BuildServeImageService(name, workdir, imageName, baseImageName)
		if err != nil {
			return fmt.Errorf("ERROR: Failed to build service: %w", err)
		}
	}
	err := service.ServeService(
		name,
		imageName,
		policies,
		envVars,
	)
	if err != nil {
		return fmt.Errorf("ERROR: Failed to serve service: %w", err)
	}
	err = service.DeployService(name, cluster)
	if err != nil {
		return fmt.Errorf("ERROR: Failed to deploy service: %w", err)
	}

	return nil
}
