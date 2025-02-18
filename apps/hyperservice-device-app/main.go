package main

import (
	"hyperservice-device-app/system" // Import the system package
	"log"
	"net/http"
)

func main() {
	// Enable logging to the standard output
    log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
	
	http.HandleFunc("/system/update", system.UpdateBinaryHandler)
	http.HandleFunc("/system/version", system.GetVersionHandler)

	// Start the server
	log.Println("Starting server on :3001...")
	err := http.ListenAndServe(":3001", nil)
	if err != nil {
		log.Println("Error starting the server:", err)
	}
}