package utils

import (
	"fmt"
	"net/http"
	"time"
)

func CheckService(url string) error {
    maxRetries := 10
    retryCount := 0

    // Loop until the service responds or maximum retries are reached
    for retryCount < maxRetries {
        // Send a GET request to check if the service is up
        resp, err := http.Get(url)
        if err == nil && resp.StatusCode == http.StatusOK {
            return nil // Service is up and running
        }
        
        if err != nil {
            fmt.Printf("🔄 Waiting for service %s to respond... Error: %v\n", url, err)
        } else {
            fmt.Printf("🔄 Waiting for service %s to respond... Status: %d\n", url, resp.StatusCode)
        }

        // Increment retry count
        retryCount++

        // Wait for 5 seconds before retrying
        time.Sleep(5 * time.Second)
    }

    // If maximum retries are exceeded
    return fmt.Errorf("❌ Service %s did not respond after %d attempts", url, maxRetries)
}
