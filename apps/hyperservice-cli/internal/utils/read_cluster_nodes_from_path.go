package utils

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

// ClusterNode represents the structure of each node in the cluster.yml file
type ClusterNode struct {
	Name      string `yaml:"name" json:"name"`
	Simulate  *bool  `yaml:"simulate,omitempty" json:"simulate,omitempty"`
	Container *struct {
		Image string `yaml:"image" json:"image"`
	} `yaml:"container,omitempty" json:"container,omitempty"`
}

// ReadClusterNodes reads the cluster.yml file in the workdir/.hyperservice/
func ReadClusterNodesFromPath(workdir string) ([]ClusterNode, error) {
	clusterFilePath := filepath.Join(workdir, ".hyperservice", "cluster.yml")
	var nodes []ClusterNode

	// Check if the cluster.yml file exists
	if _, err := os.Stat(clusterFilePath); os.IsNotExist(err) {
		return nodes, nil // File is optional, so return empty array
	}

	// Read the cluster.yml file
	fileContent, err := os.ReadFile(clusterFilePath)
	if err != nil {
		return nil, fmt.Errorf("error reading cluster file: %v", err)
	}

	// Unmarshal the YAML content
	err = yaml.Unmarshal(fileContent, &nodes)
	if err != nil {
		return nil, fmt.Errorf("error unmarshaling cluster file content: %v", err)
	}

	return nodes, nil
}
