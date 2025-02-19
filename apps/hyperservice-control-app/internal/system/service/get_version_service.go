package service

import "hyperservice-server-app/internal/system"

// GetVersion retrieves the version of the system.
// This is a simple service that returns the version string.
func GetVersion() string {
    return system.Version // Return the version that was set during the build
}