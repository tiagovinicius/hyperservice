package handler

import (
	"encoding/json"
	"hyperservice-control-plane/internal/observability/application" // Importing the 'io' package for ReadAll
	"log"
	"net/http"
)

func PostObservabilityUpHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("DEBUG: Handling /observability/up request")

	log.Printf("DEBUG: Calling ObservabilityUpApplication")
	go application.ObservabilityUpApplication()

	log.Println("DEBUG: Sending success response")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"status":  "success",
		"message": "Observability scheduled to be started successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("ERROR: Failed to encode response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
	}
	log.Println("DEBUG: Response encoded and sent successfully")
}
