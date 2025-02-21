package handler

import (
	"bytes"
	"encoding/json"
	"hyperservice-control-plane/internal/service/application"
	"io"
	"log"
	"net/http"
)

type MeshRequest struct {
	Name     string    `json:"name"`
	Workdir  string    `json:"workdir"`
	Pod      *Pod      `json:"pod,omitempty"`
	Policies *[]string `json:"policies,omitempty"`
}

type Pod struct {
	Name string `json:"name"`
}

func PostServiceStartHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("DEBUG: Handling /service/start request")

	var meshRequest MeshRequest // meshRequest agora usa a estrutura atualizada

	// Log the body content for debugging purposes (ensure it's not too large)
	if r.Body != nil {
		defer r.Body.Close()
		bodyBytes, err := io.ReadAll(r.Body) // Use io.ReadAll instead of ioutil.ReadAll
		if err != nil {
			log.Printf("ERROR: Failed to read request body: %v", err)
			http.Error(w, "Error reading request body", http.StatusInternalServerError)
			return
		}
		log.Printf("DEBUG: Received request body: %s", string(bodyBytes))
		r.Body = io.NopCloser(bytes.NewReader(bodyBytes)) // Reset the body to allow further reading
	}

	// Decode the request body into the meshRequest object
	log.Println("DEBUG: Decoding request body into meshRequest")
	if err := json.NewDecoder(r.Body).Decode(&meshRequest); err != nil {
		log.Printf("ERROR: Failed to decode request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Ensure required fields are present
	if meshRequest.Name == "" || meshRequest.Workdir == "" {
		log.Printf("ERROR: Missing required fields (Name or Workdir)")
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	// Verifica se 'Pod' é nil antes de passar para a função StartServiceService
	var podName string
	if meshRequest.Pod != nil {
		podName = meshRequest.Name
	}

	// Se Policies for nil, podemos passar um slice vazio para evitar problemas
	if meshRequest.Policies == nil {
		meshRequest.Policies = &[]string{}
	}

	log.Printf("DEBUG: MeshRequest decoded successfully: %+v", meshRequest)

	// Debugging: Print the decoded body for inspection
	go application.ServiceStartApplication(
		meshRequest.Name,
		meshRequest.Workdir,
		podName,
		*meshRequest.Policies,
	)

	// Send a success response
	log.Println("DEBUG: Sending success response")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"status":  "success",
		"message": "Service scheduled to be started successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("ERROR: Failed to encode response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
	}
	log.Println("DEBUG: Response encoded and sent successfully")
}
