package utils

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
)

// KillProcessOnPort attempts to kill the process running on the specified port
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
	pid := strings.TrimSpace(string(output))
	fmt.Printf("Killing process with PID %s on port %s...\n", pid, port)

	// Kill the process
	pidInt, err := strconv.Atoi(pid)
	if err != nil {
		return fmt.Errorf("failed to convert PID to integer: %w", err)
	}

	// Kill the process
	process := syscall.Kill(pidInt, syscall.SIGKILL)
	if process != nil {
		return fmt.Errorf("failed to kill process with PID %d: %w", pidInt, process)
	}

	fmt.Printf("✅ Process with PID %d killed successfully.\n", pidInt)
	return nil
}