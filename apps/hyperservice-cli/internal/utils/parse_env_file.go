package utils

import (
	"bufio"
	"strings"
)

// ParseEnvFile parses the contents of an .env file and returns a map[string]string
func ParseEnvFile(envContent string) map[string]string {
	envVars := make(map[string]string)
	scanner := bufio.NewScanner(strings.NewReader(envContent))

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Ignore empty lines and comments
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Split key and value
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue // Ignore malformed lines
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		// Remove optional surrounding quotes from value
		value = strings.Trim(value, "\"'")

		envVars[key] = value
	}

	return envVars
}
