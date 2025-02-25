package business_logic

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v2"
)

// ImportConfig represents the expected structure of import.yml
type ImportConfig struct {
	Image string     `yaml:"image"`
	Git   *GitConfig `yaml:"git"`
}

type GitConfig struct {
	Url     string `yaml:"url"`
	Workdir string `yaml:"workdir"`
}

// ReadImportFile reads the image from import.yml
func ReadImportFile(path string) (*ImportConfig, error) {
	file, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read YAML file: %w", err)
	}

	var config ImportConfig
	err = yaml.Unmarshal(file, &config)
	if err != nil {
		return nil, fmt.Errorf("failed to parse YAML file: %w", err)
	}

	return &config, nil
}
