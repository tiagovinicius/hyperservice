package main

import (
	"fmt"
	meshHandler "hyperservice-control-plane/internal/mesh/handler"
	systemHandler "hyperservice-control-plane/internal/system/handler"
	"log"
	"net/http"
)

func main() {
	// Log that the server is starting
	log.Println("INFO: Starting server on port 8080...")

	// Setup routing
	http.HandleFunc("/system/version", systemHandler.GetVersionHandler)
	http.HandleFunc("/mesh/up", meshHandler.PostMeshUpHandler)

	fmt.Println("Server is running on port 3002...")
	if err := http.ListenAndServe(":3002", nil); err != nil {
		fmt.Printf("Error starting server: %v\n", err)
	}
}
