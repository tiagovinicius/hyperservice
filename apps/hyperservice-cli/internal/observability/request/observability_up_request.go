package request

import (
	"fmt"
	"net/http"
)

// ObservabilityUpRequest sends a request to start observability services
func ObservabilityUpRequest() error {
	url := "http://localhost:3002/observability/up"
	client := &http.Client{}
	request, err := http.NewRequest("POST", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	request.Header.Set("User-Agent", "insomnia/10.3.1")

	resp, err := client.Do(request)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	return nil
}
