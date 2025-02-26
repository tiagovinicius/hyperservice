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

// ServiceStartRequest represents the payload for the service start request
type ServiceStartRequest struct {
	Name      string            `json:"name"`
	Container map[string]string `json:"container,omitempty"`
	Workdir   string            `json:"workdir"`
	Policies  []string          `json:"policies,omitempty"`
	Env       map[string]string `json:"env,omitempty"`
}

// StartService sends a request to start a service
func StartServiceRequest(name, workdir string, image string) (string, error) {
	envFilePath := filepath.Join(workdir, "apps", name, ".env")

	// Read policies from the optional directory
	policies, err := utils.ReadPoliciesFromDir(workdir + "/apps/" + name)
	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
		policies = []string{}
	}

	envVars := make(map[string]string)
	if data, err := os.ReadFile(envFilePath); err == nil {
		lines := utils.ParseEnvFile(string(data))
		for key, value := range lines {
			envVars[key] = value
		}
	} else {
		fmt.Printf("⚠️ Warning: Failed to read .env file: %v\n", err)
	}

	requestBody, err := json.Marshal(ServiceStartRequest{
		Name: name,
		Container: map[string]string{
			"image": image,
		},
		Workdir:  workdir,
		Policies: policies,
		Env:      envVars,
	})
	if err != nil {
		return "", fmt.Errorf("failed to marshal request body: %w", err)
	}

	resp, err := http.Post("http://localhost:3002/service/start", "application/json", bytes.NewBuffer(requestBody))
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
