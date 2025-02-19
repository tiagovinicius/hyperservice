package handler

import (
	"encoding/json"
	"hyperservice-server-app/internal/system/service"
	"log"
	"net/http"
)

// GetVersionHandler is the HTTP handler for the /system/version endpoint.
// It is responsible for handling the request, calling the service, and sending the response.
func GetVersionHandler(w http.ResponseWriter, r *http.Request) {
    log.Println("INFO: Handling /system/version request")

    // Call the service to get the version
    version := service.GetVersion()

    // If version is not set, return "undefined"
    if version == "" {
        log.Println("WARN: Version not set during build, returning 'undefined'")
        version = "undefined"
    } else {
        log.Printf("INFO: Returning version: %s", version)
    }

    // Prepare the response data
    response := map[string]string{
        "version": version,
    }

    // Set the appropriate headers and send the response
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    if err := json.NewEncoder(w).Encode(response); err != nil {
        log.Printf("ERROR: Failed to encode version response: %v", err)
        http.Error(w, err.Error(), http.StatusInternalServerError)
    }
}