package service

import (
	"fmt"
	"os"
	"os/exec"
)

// Start runs the service in the background and logs its output.
func Start() error {
	fmt.Println("Starting service...")

	workDir := os.Getenv("HYPERSERVICE_WORKDIR_PATH")
	fmt.Printf("HYPERSERVICE_WORKDIR_PATH: %s\n", workDir)
	if workDir == "" {
		fmt.Println("❌ environment variable HYPERSERVICE_WORKDIR_PATH is not set")
		workDir = "/"
		fmt.Printf("Defaulting workDir to %s\n", workDir)
	}

	serviceName := os.Getenv("SERVICE_NAME")
	fmt.Printf("SERVICE_NAME: %s\n", serviceName)
	if serviceName == "" {
		return fmt.Errorf("❌ environment variable SERVICE_NAME is not set")
	}

	serve := os.Getenv("HYPERSERVICE_SERVE") == "true"
	fmt.Printf("HYPERSERVICE_SERVE: %v\n", serve)

	// Change to the working directory
	fmt.Printf("📁 Changing working directory to: %s\n", workDir)
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

	// Configuração do output para capturar os logs
	fmt.Println("📤 Attaching stdout and stderr to process...")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Start the process
	fmt.Println("🏁 Starting the command...")
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("❌ failed to start service '%s': %v", serviceName, err)
	}
	fmt.Println("✅ Command started successfully")

	// Wait in a separate goroutine to properly clean up the process
	go func() {
		fmt.Printf("🕒 Waiting for service '%s' to finish...\n", serviceName)
		err := cmd.Wait()
		if err != nil {
			fmt.Printf("❌ Service '%s' exited with error: %v\n", serviceName, err)
		} else {
			fmt.Printf("✅ Service '%s' stopped successfully.\n", serviceName)
		}
	}()

	return nil
}
