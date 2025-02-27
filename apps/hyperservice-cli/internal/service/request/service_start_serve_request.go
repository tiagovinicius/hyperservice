package request

import (
	"bytes"
	"encoding/json"
	"fmt"
	"hyperservice-cli/internal/utils"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

// StartServeServiceRequest sends a request to start a service with container image
func StartServeServiceRequest(name, workdir, image string) (string, error) {
	meshPoliciesDir := filepath.Join(workdir, "apps", name)
	servicePoliciesDir := filepath.Join(workdir, "apps", name)
	envFilePath := filepath.Join(workdir, "apps", name, ".env")

	meshPolicies, err := utils.ReadPoliciesFromDir(meshPoliciesDir)
	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
		meshPolicies = []string{}
	}

	servicePolicies, err := utils.ReadPoliciesFromDir(servicePoliciesDir)
	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
		servicePolicies = []string{}
	}

	policies := append(meshPolicies, servicePolicies...)

	envVars := make(map[string]string)
	if data, err := os.ReadFile(envFilePath); err == nil {
		lines := utils.ParseEnvFile(string(data))
		for key, value := range lines {
			envVars[key] = value
		}
	} else {
		fmt.Printf("⚠️ Warning: Failed to read .env file: %v\n", err)
	}

	requestBody, err := json.Marshal(ServiceStartServeRequest{
		Name: name,
		Container: map[string]string{
			"image": image,
		},
		Workdir:  workdir,
		Build:    true,
		Policies: policies,
		Env:      envVars,
	})
	if err != nil {
		return "", fmt.Errorf("failed to marshal request body: %w", err)
	}

	resp, err := http.Post("http://localhost:3002/service/start/serve", "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response body: %w", err)
	}

	return string(body), nil
}
