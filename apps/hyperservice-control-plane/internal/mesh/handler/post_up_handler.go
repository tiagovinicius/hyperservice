package handler

import (
	"bytes"
	"encoding/json"
	"io"   // Importing the 'io' package for ReadAll
	"log"
	"net/http"
	"hyperservice-control-plane/internal/mesh/service"
	"hyperservice-control-plane/internal/mesh"
)

// PostMeshUpHandler handles the POST request for /meshes/up.
func PostMeshUpHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("DEBUG: Handling /meshes/up request")

	var meshRequest mesh.MeshRequest // mesh is now correctly imported

	// Log the body content for debugging purposes (ensure it's not too large)
	if r.Body != nil {
		defer r.Body.Close()
		bodyBytes, err := io.ReadAll(r.Body)  // Use io.ReadAll instead of ioutil.ReadAll
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

	log.Printf("DEBUG: MeshRequest decoded successfully: %+v", meshRequest)

	// Call the service to process the mesh creation
	log.Printf("DEBUG: Calling MeshUpService")
	err := service.MeshUpService() // Pass the name of the mesh
	if err != nil {
		log.Printf("ERROR: Failed to create mesh: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Send a success response
	log.Println("DEBUG: Sending success response")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"status":  "success",
		"message": "Mesh created successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("ERROR: Failed to encode response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
	}
	log.Println("DEBUG: Response encoded and sent successfully")
}