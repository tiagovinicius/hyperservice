package handler

import (
	"bytes"
	"encoding/json"
	"hyperservice-control-plane/internal/service/application"
	"io"
	"log"
	"net/http"
)

type ServiceStartServeRequest struct {
	Name      string            `json:"name"`
	Pod       *Pod              `json:"pod,omitempty"`
	Build     bool              `json:"build,omitempty"`
	Workdir   string            `json:"workdir,omitempty"`
	Container *Container        `json:"container"`
	Policies  *[]string         `json:"policies,omitempty"`
	EnvVars   map[string]string `json:"env,omitempty"`
}

func PostServiceStartServeHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("DEBUG: Handling /service/start/serve request")

	var request ServiceStartServeRequest

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

	// Decode the request body into the request object
	log.Println("DEBUG: Decoding request body into request")
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		log.Printf("ERROR: Failed to decode request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Ensure required fields are present
	if request.Name == "" {
		log.Printf("ERROR: Missing required fields: name")
		http.Error(w, "Missing required field: name", http.StatusBadRequest)
		return
	}

	// Ensure required fields are present
	if !request.Build && (request.Container == nil || request.Container.Image == "") {
		log.Printf("ERROR: Missing required fields: container.image")
		http.Error(w, "Missing required field: container.image", http.StatusBadRequest)
		return
	}

	// Ensure required fields are present
	if request.Build && request.Workdir == "" {
		log.Printf("ERROR: Missing required fields: workdir")
		http.Error(w, "Missing required field: workdir", http.StatusBadRequest)
		return
	}

	// Verifica se 'Pod' é nil antes de passar para a função StartServiceService
	var podName string
	if request.Pod != nil {
		podName = request.Name
	}

	// Se Policies for nil, podemos passar um slice vazio para evitar problemas
	if request.Policies == nil {
		request.Policies = &[]string{}
	}

	// Se EnvVars for nil, podemos passar um slice vazio para evitar problemas
	if request.EnvVars == nil {
		request.EnvVars = map[string]string{}
	}

	log.Printf("DEBUG: ServiceStartServeRequest decoded successfully: %+v", request)
	log.Printf("DEBUG:- name: %s, imageName: %s,  podName: %s, build: %t, workdir: %s", request.Name, request.Container.Image, podName, request.Build, request.Workdir)

	// Debugging: Print the decoded body for inspection
	go application.ServiceServeApplication(
		request.Name,
		request.Container.Image,
		podName,
		*request.Policies,
		request.EnvVars,
		request.Build,
		request.Workdir,
	)

	// Send a success response
	log.Println("DEBUG: Sending success response")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"status":  "success",
		"message": "Service scheduled to serve successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("ERROR: Failed to encode response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
	}
	log.Println("DEBUG: Response encoded and sent successfully")
}
