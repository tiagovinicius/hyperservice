package main

import (
	"hyperservice-dataplane/observability"
	"hyperservice-dataplane/service"
	"hyperservice-dataplane/system" // Import the system package
	"log"
	"net/http"
)

func main() {
	// Enable logging to the standard output
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)

	http.HandleFunc("/system/update", system.UpdateBinaryHandler)
	http.HandleFunc("/system/version", system.GetVersionHandler)
	
	observability.CollectMetrics()
	service.Start()

	// Start the server
	log.Println("Starting server on :3001...")
	err := http.ListenAndServe(":3001", nil)
	if err != nil {
		log.Println("Error starting the server:", err)
	}
}
