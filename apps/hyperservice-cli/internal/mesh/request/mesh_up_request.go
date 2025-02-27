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

	// Configuração de tempo
	totalTimeout := 180 * time.Second  // Timeout total de 3 minutos
	progressDuration := 90 * time.Second // Tempo para alcançar 90%
	interval := 3 * time.Second         // Intervalo de verificação
	barSize := 30                       // Tamanho visual da barra

	// Criar barra inicial com 30% preenchido
	progressBar := make([]rune, barSize)
	initialFill := barSize * 30 / 100 // Começa em 30%
	for i := 0; i < barSize; i++ {
		if i < initialFill {
			progressBar[i] = '='
		} else {
			progressBar[i] = ' '
		}
	}

	fmt.Print("⏳[")
	fmt.Print(string(progressBar)) // Exibe a barra inicial
	fmt.Print("]")
	os.Stdout.Sync()

	startTime := time.Now()

	for {
		// Checa se a malha está pronta
		resp, err := client.Get(checkURL)
		if err == nil && resp.StatusCode == http.StatusOK {
			resp.Body.Close()
			fmt.Printf("\r⏳[%s] ✅ Mesh is ready!\n", string(progressBar))
			return nil
		}
		if resp != nil {
			resp.Body.Close()
		}

		// Calcula tempo decorrido
		elapsed := time.Since(startTime)
		if elapsed >= totalTimeout {
			fmt.Printf("\r⏳[%s] ⛔ Timeout: mesh did not become ready within 3 minutes\n", string(progressBar))
			return fmt.Errorf("\n⛔ Timeout: mesh did not become ready within 3 minutes")
		}

		// Atualiza a barra de progresso **até 90% em 90s**
		if elapsed <= progressDuration {
			progress := 30 + int((elapsed.Seconds()/progressDuration.Seconds())*60) // Vai de 30% a 90%
			fillCount := barSize * progress / 100
			for i := 0; i < fillCount; i++ {
				progressBar[i] = '='
			}
		}

		// Atualiza a barra de progresso na mesma linha
		fmt.Printf("\r⏳[%s]", string(progressBar))
		os.Stdout.Sync()
		time.Sleep(interval)
	}
}