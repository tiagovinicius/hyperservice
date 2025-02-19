package main

import (
	"fmt"
	"hyperservice-server-app/internal/system/handler"
	"log"
	"net/http"
)

func main() {
    // Log that the server is starting
    log.Println("INFO: Starting server on port 8080...")

    // Setup routing
    http.HandleFunc("/system/version", handler.GetVersionHandler)

    fmt.Println("Server is running on port 3002...")
    if err := http.ListenAndServe(":3002", nil); err != nil {
        fmt.Printf("Error starting server: %v\n", err)
    }
}