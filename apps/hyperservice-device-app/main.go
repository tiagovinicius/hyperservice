package main

import (
	"fmt"
	"net/http"
	"hyperservice-device-app/system"  // Import the system package
)

func main() {
	http.HandleFunc("/system/update", system.UpdateBinaryHandler)
	http.HandleFunc("/system/version", system.GetVersionHandler)

	// Start the server
	fmt.Println("Starting server on :8080...")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Println("Error starting the server:", err)
	}
}