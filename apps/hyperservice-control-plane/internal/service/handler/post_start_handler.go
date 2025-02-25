package handler

import (
	"bytes"
	"encoding/json"
	"hyperservice-control-plane/internal/service/application"
	"io"
	"log"
	"net/http"
)

type ServiceStartRequest struct {
	Name      string            `json:"name"`
	Workdir   string            `json:"workdir"`
	Pod       *Pod              `json:"pod,omitempty"`
	Container *Container        `json:"container,omitempty"`
	Policies  *[]string         `json:"policies,omitempty"`
	EnvVars   map[string]string `json:"env,omitempty"`
}

type PartialServiceStartRequest struct {
	Name      string      `json:"name"`
	Pod       *Pod        `json:"pod,omitempty"`
	Container *Container  `json:"container"`
	Policies  *[]string   `json:"policies,omitempty"`
	EnvVars   interface{} `json:"env,omitempty"` // Mudar para interface{} para capturar qualquer tipo
}

type Pod struct {
	Name string `json:"name"`
}

type Container struct {
	Image string `json:"image"`
}

func PostServiceStartHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("DEBUG: Handling /service/start request")

	var request ServiceStartRequest // request agora usa a estrutura atualizada

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
	if request.Name == "" || request.Workdir == "" {
		log.Printf("ERROR: Missing required fields (Name or Workdir)")
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	// Verifica se 'Pod' é nil antes de passar para a função StartServiceService
	var podName string
	if request.Pod != nil {
		podName = request.Name
	}

	// Verifica se 'Pod' é nil antes de passar para a função StartServiceService
	var imageName string
	if request.Container != nil {
		imageName = request.Container.Image
	}

	// Se Policies for nil, podemos passar um slice vazio para evitar problemas
	if request.Policies == nil {
		request.Policies = &[]string{}
	}

	// Se EnvVars for nil, podemos passar um slice vazio para evitar problemas
	if request.EnvVars == nil {
		request.EnvVars = map[string]string{}
	}

	log.Printf("DEBUG: ServiceStartRequest decoded successfully: %+v", request)
	log.Printf("DEBUG:- name: %s, workdir: %s, imageName: %s,  podName: %s", request.Name, request.Workdir, imageName, podName)

	// Debugging: Print the decoded body for inspection
	go application.ServiceStartApplication(
		request.Name,
		request.Workdir,
		imageName,
		podName,
		*request.Policies,
		request.EnvVars,
	)

	// Send a success response
	log.Println("DEBUG: Sending success response")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"status":  "success",
		"message": "Service scheduled to start successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("ERROR: Failed to encode response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
	}
	log.Println("DEBUG: Response encoded and sent successfully")
}
