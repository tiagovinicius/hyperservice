package service

import (
	"fmt"
	"os"
	"os/exec"
)

// Start runs the service in the background and logs its output.
func Start() error {
	workDir := os.Getenv("HYPERSERVICE_WORKDIR_PATH")
	if workDir == "" {
		return fmt.Errorf("❌ environment variable HYPERSERVICE_WORKDIR_PATH is not set")
	}
	serviceName := os.Getenv("SERVICE_NAME")
	if serviceName == "" {
		return fmt.Errorf("❌ environment variable SERVICE_NAME is not set")
	}
	serve := os.Getenv("HYPERSERVICE_SERVE") == "true"

	// Change to the working directory
	if err := os.Chdir(workDir); err != nil {
		return fmt.Errorf("❌ failed to navigate to %s: %v", workDir, err)
	}

	fmt.Printf("🚀 Starting service '%s' in background...\n", serviceName)

	var cmd *exec.Cmd
	if serve {
		fmt.Printf("🔧 Service '%s' will be served\n", serviceName)
		cmd = exec.Command("moon", serviceName+":serve")
	} else {
		fmt.Printf("🔧 Service '%s' will run in dev mode\n", serviceName)
		cmd = exec.Command("moon", serviceName+":dev")
	}

	// Configuração do output para capturar os logs do collectd
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Start the process
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("❌ failed to start service '%s': %v", serviceName, err)
	}

	// Wait in a separate goroutine to properly clean up the process
	go func() {
		err := cmd.Wait()
		if err != nil {
			fmt.Printf("❌ Service '%s' exited with error: %v\n", serviceName, err)
		} else {
			fmt.Printf("✅ Service '%s' stopped successfully.\n", serviceName)
		}
	}()

	return nil
}
