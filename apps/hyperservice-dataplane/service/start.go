package service

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
)

// Start runs the service in background and logs output
func Start() error {
	workDir := os.Getenv("HYPERSERVICE_WORKDIR_PATH")
	if workDir == "" {
		return fmt.Errorf("environment variable HYPERSERVICE_WORKDIR_PATH is not set")
	}
	serviceName := os.Getenv("SERVICE_NAME")
	if workDir == "" {
		return fmt.Errorf("environment variable SERVICE_NAME is not set")
	}
	serve := os.Getenv("HYPERSERVICE_SERVE") == "true"

	// Change to the working directory
	if err := os.Chdir(workDir); err != nil {
		return fmt.Errorf("failed to navigate to %s: %v", workDir, err)
	}

	fmt.Printf("Starting service %s in background\n", serviceName)

	var cmd *exec.Cmd
	if(serve) {
		fmt.Printf("Service %s will be served\n", serviceName)
		cmd = exec.Command("moon", serviceName+":serve")
	} else {
		fmt.Printf("Service %s will be dev\n", serviceName)
		// Execute the moon command in background
		cmd = exec.Command("moon", serviceName+":dev")
	}
	// Create pipes to capture logs
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to create stdout pipe: %v", err)
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		return fmt.Errorf("failed to create stderr pipe: %v", err)
	}

	// Start process
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start service %s: %v", serviceName, err)
	}

	// Goroutines to capture logs
	go logOutput(stdout, "STDOUT")
	go logOutput(stderr, "STDERR")

	return nil
}

// logOutput reads and prints logs from the given pipe
func logOutput(pipe io.ReadCloser, prefix string) {
	scanner := bufio.NewScanner(pipe)
	for scanner.Scan() {
		fmt.Printf("[%s] %s\n", prefix, scanner.Text())
	}
	pipe.Close()
}
