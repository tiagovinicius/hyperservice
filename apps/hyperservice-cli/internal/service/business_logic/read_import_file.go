package business_logic

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v2"
)

// ImportConfig represents the expected structure of import.yml
type ImportConfig struct {
	Image string `yaml:"image"`
}

// ReadImportFile reads the image from import.yml
func ReadImportFile(path string) (string, error) {
	file, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("failed to read YAML file: %w", err)
	}

	var config ImportConfig
	err = yaml.Unmarshal(file, &config)
	if err != nil {
		return "", fmt.Errorf("failed to parse YAML file: %w", err)
	}

	return config.Image, nil
}
