package business_logic

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// ContainerConfig representa a estrutura do arquivo container.yml
type ContainerConfig struct {
	Image string `yaml:"image"`
}

// ReadContainerFile lê o arquivo container.yml e retorna a configuração do container
func ReadContainerFile(filePath string) (*ContainerConfig, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read container.yml: %w", err)
	}

	var config ContainerConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse container.yml: %w", err)
	}

	return &config, nil
}
