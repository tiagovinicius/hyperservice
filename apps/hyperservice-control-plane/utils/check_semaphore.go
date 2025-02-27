package utils

import (
	"fmt"
	"os"
	"strings"
)

// CheckSemaphore reads the content of a semaphore file and returns its value as a string
func CheckSemaphore(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return "false", nil // Se o arquivo não existir, assume que o semáforo está "false"
		}
		return "", fmt.Errorf("failed to read semaphore file: %w", err)
	}
	return strings.TrimSpace(string(data)), nil
}