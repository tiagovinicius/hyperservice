package request

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// MeshUpRequest represents the JSON body for the mesh up request
type MeshUp struct {
	Policies []string `json:"policies"`
}

// MeshUpRequest sends the HTTP request to bring the mesh up
func MeshUpRequest(policies []string) error {
	url := "http://localhost:3002/mesh/up"
	payload := MeshUp{Policies: policies}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("error marshaling JSON: %v", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("error creating request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "hyperservice-cli/1.0")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("error making request: %v", err)
	}
	defer resp.Body.Close()

	// Read the response body correctly
	body, readErr := io.ReadAll(resp.Body)
	if readErr != nil {
		return fmt.Errorf("error reading response body: %v", readErr)
	}
	
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to schedule mesh up. Status: %d, Response: %s", resp.StatusCode, string(body))
	}

	fmt.Println("✅ Mesh successfully scheduled to up!")
	return nil
}