package request

import (
	"bytes"
	"encoding/json"
	"fmt"
	"hyperservice-cli/internal/utils"
	"io"
	"net/http"
)

// ServiceStartRequest represents the payload for the service start request
type ServiceStartRequest struct {
	Name     string   `json:"name"`
	Workdir  string   `json:"workdir"`
	Policies []string `json:"policies"`
}

// StartService sends a request to start a service
func StartServiceRequest(name, workdir string) (string, error) {
	// Read policies from the optional directory
	policies, err := utils.ReadPoliciesFromDir(workdir + "/apps/" + name)
	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
		policies = []string{}
	}

	requestBody, err := json.Marshal(ServiceStartRequest{
		Name:     name,
		Workdir:  workdir,
		Policies: policies,
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
