package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
)

// KillProcessOnPort attempts to kill the process running on the specified port,
// but ensures it does not kill itself.
func KillProcessOnPort(port string) error {
	// Find the PID of the process using the port
	cmd := exec.Command("lsof", "-t", "-i", fmt.Sprintf(":%s", port))
	output, _ := cmd.CombinedOutput()

	// If there's no output, no process is using the port
	if len(output) == 0 {
		fmt.Println("No process found running on the specified port.")
		return nil
	}

	// Get the PID from the output
	pidStr := strings.TrimSpace(string(output))
	pid, err := strconv.Atoi(pidStr)
	if err != nil {
		return fmt.Errorf("failed to convert PID to integer: %w", err)
	}

	// Get the current process PID
	selfPID := os.Getpid()

	// Ensure we are not killing ourselves
	if pid == selfPID {
		fmt.Printf("⚠️ Skipping process with PID %d (this program itself).\n", pid)
		return nil
	}

	fmt.Printf("Killing process with PID %d on port %s...\n", pid, port)

	// Kill the process
	err = syscall.Kill(pid, syscall.SIGKILL)
	if err != nil {
		return fmt.Errorf("failed to kill process with PID %d: %w", pid, err)
	}

	fmt.Printf("✅ Process with PID %d killed successfully.\n", pid)
	return nil
}