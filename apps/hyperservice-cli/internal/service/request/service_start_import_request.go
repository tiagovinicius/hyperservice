package request

import (
	"bytes"
	"encoding/json"
	"fmt"
	"hyperservice-cli/internal/utils"
	"io"
	"net/http"
	"path/filepath"
)

// ServiceStartServeRequest represents the payload for the serve start request
type ServiceStartServeRequest struct {
	Name      string            `json:"name"`
	Container map[string]string `json:"container"`
	Policies  []string          `json:"policies"`
}

// StartImportServiceRequest sends a request to start a service with container image
func StartImportServiceRequest(name, workdir, image string, importWorkdir string) (string, error) {
	meshPoliciesDir := filepath.Join(workdir, "apps", name, ".hyperservice/cache/git")
	servicePoliciesDir := filepath.Join(workdir, "apps", name, ".hyperservice/cache/git/apps", importWorkdir, name)

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

	requestBody, err := json.Marshal(ServiceStartServeRequest{
		Name: name,
		Container: map[string]string{
			"image": image,
		},
		Policies: policies,
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
