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
	interval := 3 * time.Second
	maxSteps := 180 / 3 // 180s / 3s = 24 steps
	barSize := 30       // Define o tamanho da barra visualmente

	// Criar a barra vazia
	progressBar := make([]rune, barSize)
	for i := range progressBar {
		progressBar[i] = ' ' // Inicialmente preenchida com espaços
	}

	fmt.Print("⏳[")
	fmt.Print(string(progressBar)) // Imprime a barra vazia
	fmt.Print("]")
	os.Stdout.Sync()

	// Live progress updates
	for i := 0; i < maxSteps; i++ {
		resp, err := client.Get(checkURL)
		if err == nil && resp.StatusCode == http.StatusOK {
			resp.Body.Close()
			fmt.Printf("\r⏳[%s] ✅ Mesh is ready!\n", string(progressBar))
			return nil
		}
		if resp != nil {
			resp.Body.Close()
		}

		// Calcula a proporção da barra preenchida
		fillCount := (i + 1) * barSize / maxSteps
		for j := 0; j < fillCount; j++ {
			progressBar[j] = '=' // Substitui espaços por '=' conforme o tempo passa
		}

		// Atualiza a barra na mesma linha
		fmt.Printf("\r⏳[%s]", string(progressBar))
		os.Stdout.Sync()
		time.Sleep(interval)
	}

	fmt.Printf("\r⏳ Waiting for mesh to be ready... [%s] ⛔ Timeout: mesh did not become ready within 2 minutes\n", string(progressBar))
	return fmt.Errorf("\n⛔ Timeout: mesh did not become ready within 2 minutes")
}