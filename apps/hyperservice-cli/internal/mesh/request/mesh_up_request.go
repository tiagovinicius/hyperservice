package request

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
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

	return waitForMeshReady()
}

// waitForMeshReady checks the /mesh/ready endpoint with a timeout of 90 seconds
func waitForMeshReady() error {
	checkURL := "http://localhost:3002/mesh/ready"
	client := &http.Client{}
	interval := 5 * time.Second
	maxSteps := 120 / 5 // 120s / 5s = 24 steps

	fmt.Print("⏳[")
	os.Stdout.Sync() // Força a exibição inicial

	for i := 0; i < maxSteps; i++ {
		resp, err := client.Get(checkURL)
		if err == nil && resp.StatusCode == http.StatusOK {
			resp.Body.Close()
			fmt.Println("] ✅ Mesh is ready!")
			os.Stdout.Sync()
			return nil
		}
		if resp != nil {
			resp.Body.Close()
		}

		// Atualiza a barra de progresso na mesma linha
		fmt.Print("=")
		os.Stdout.Sync() // Força a exibição da barra
		time.Sleep(interval)
	}

	fmt.Println("] ⛔ Timeout: mesh did not become ready within 2 minutes")
	os.Stdout.Sync()
	return fmt.Errorf("\n⛔ Timeout: mesh did not become ready within 2 minutes")
}