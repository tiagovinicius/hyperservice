package handler

import (
	"bytes"
	"encoding/json"
	"hyperservice-control-plane/internal/mesh/application"
	"hyperservice-control-plane/internal/mesh/model"
	"io" // Importing the 'io' package for ReadAll
	"log"
	"net/http"
)

// PostMeshUpHandler handles the POST request for /meshes/up.
func PostMeshUpHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("DEBUG: Handling /meshes/up request")

	var request model.MeshRequest // mesh is now correctly imported

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

	// Ensure required fields are present
	if request.Cluster != nil {
		for _, node := range request.Cluster {
			if node.Name == "" {
				log.Printf("ERROR: Missing required field: cluster[].name")
				http.Error(w, "Missing required field: cluster[].name", http.StatusBadRequest)
				return
			}
		}
	}

	// Decode the request body into the request object
	log.Println("DEBUG: Decoding request body into request")
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		log.Printf("ERROR: Failed to decode request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	log.Printf("DEBUG: MeshRequest decoded successfully: %+v", request)

	// Call the service to process the mesh creation
	log.Printf("DEBUG: Calling MeshUpApplication")
	go application.MeshUpApplication(&request.Cluster)

	// Send a success response
	log.Println("DEBUG: Sending success response")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"status":  "success",
		"message": "Mesh scheduled to be created successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("ERROR: Failed to encode response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
	}
	log.Println("DEBUG: Response encoded and sent successfully")
}
