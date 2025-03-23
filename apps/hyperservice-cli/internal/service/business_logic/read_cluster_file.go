package business_logic

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// ClusterConfig representa a estrutura do arquivo cluster.yml
type ClusterConfig struct {
	Cluster []string `yaml:"cluster"`
}

// ReadClusterFile lê o arquivo cluster.yml e retorna a configuração do cluster
func ReadClusterFile(filePath string) (*ClusterConfig, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read cluster.yml: %w", err)
	}

	var config ClusterConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse cluster.yml: %w", err)
	}

	return &config, nil
}
