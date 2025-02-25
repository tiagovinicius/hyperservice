package request

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// ServiceStartServeRequest represents the payload for the serve start request
type ServiceStartServeRequest struct {
	Name      string            `json:"name"`
	Container map[string]string `json:"container"`
}

// StartServeServiceRequest sends a request to start a service with container image
func StartServeServiceRequest(name, image string) (string, error) {
	requestBody, err := json.Marshal(ServiceStartServeRequest{
		Name: name,
		Container: map[string]string{
			"image": image,
		},
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
