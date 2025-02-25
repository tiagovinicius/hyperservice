package main

import (
	"fmt"
	meshHandler "hyperservice-control-plane/internal/mesh/handler"
	"hyperservice-control-plane/internal/mesh/infrastructure"
	observabilityHandler "hyperservice-control-plane/internal/observability/handler"
	serviceHandler "hyperservice-control-plane/internal/service/handler"
	systemHandler "hyperservice-control-plane/internal/system/handler"
	"log"
	"net/http"
)

func main() {
	// Log that the server is starting
	log.Println("INFO: Starting server on port 3002...")
	infrastructure.GetKubernetesClientSet("hyperservice")

	// Setup routing
	http.HandleFunc("/system/version", systemHandler.GetVersionHandler)
	http.HandleFunc("/mesh/up", meshHandler.PostMeshUpHandler)
	http.HandleFunc("/observability/up", observabilityHandler.PostObservabilityUpHandler)
	http.HandleFunc("/service/start", serviceHandler.PostServiceStartHandler)
	http.HandleFunc("/service/start/serve", serviceHandler.PostServiceStartServeHandler)

	infrastructure.MakeKubernetesPortForward("kuma-system", "kuma-control-plane", "5681", ":5681")
	infrastructure.MakeKubernetesPortForward("mesh-observability", "grafana", "3000", "80")
	infrastructure.MakeKubernetesPortForward("mesh-observability", "prometheus", "9090", "80")

	fmt.Println("Server is running on port 3002...")
	if err := http.ListenAndServe(":3002", nil); err != nil {
		fmt.Printf("Error starting server: %v\n", err)
	}
}
