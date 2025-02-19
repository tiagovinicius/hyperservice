package utils

import (
	"fmt"
	"log"
)

// logError is a helper function to log and return an error with a message.
func LogError(message string, err error) error {
	log.Printf("ERROR: %s: %v", message, err)
	return fmt.Errorf("%s: %w", message, err)
}