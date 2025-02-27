package handler

import (
	"hyperservice-control-plane/internal/mesh/application" // Importing the 'io' package for ReadAll
	"log"
	"net/http"
)

// GetMeshReadyHandler handles the POST request for /meshes/ready.
func GetMeshReadyHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("DEBUG: Handling /meshes/ready request")

	// Call the service to process the mesh creation
	log.Printf("DEBUG: Calling MeshReadyApplication")
	err := application.MeshReadyApplication()
	if(err != nil) {
		http.Error(w, "false", http.StatusServiceUnavailable)
		return
	}

	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("true"))
}
