package utils

import (
	"fmt"
	"os"
	"path/filepath"
)

// ReadPoliciesFromDir reads all manifest files from .hyperservice/policies/
func ReadPoliciesFromDir(workdir string) ([]string, error) {
	policiesDir := filepath.Join(workdir, ".hyperservice/policies")
	var policies []string

	// Check if the directory exists
	if _, err := os.Stat(policiesDir); os.IsNotExist(err) {
		return policies, nil // Directory is optional, so return empty array
	}

	// Read all files in the directory
	files, err := os.ReadDir(policiesDir)
	if err != nil {
		return nil, fmt.Errorf("error reading policies directory: %v", err)
	}

	for _, file := range files {
		if file.IsDir() {
			continue // Skip directories
		}

		filePath := filepath.Join(policiesDir, file.Name())
		content, err := os.ReadFile(filePath)
		if err != nil {
			fmt.Printf("⚠️ Warning: Could not read policy file %s: %v\n", file.Name(), err)
			continue
		}

		policies = append(policies, string(content))
	}

	return policies, nil
}