package system

import (
	"fmt"
	"net/http"
)

var version = "unknown" // Default version, will be set at build time

// GetVersionHandler returns the current version of the app
func GetVersionHandler(w http.ResponseWriter, r *http.Request) {
	// Respond with the current version
	fmt.Fprintf(w, "Current version: %s\n", version)
}