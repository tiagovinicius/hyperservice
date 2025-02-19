package utils

import (
	"fmt"
	"os"
	"os/exec"
)

// RestartApplication restarts the application by executing the current binary again
// We inject exec.Command to allow mocking in tests
func RestartApplication(binaryPath string, commandFactory func(string, ...string) *exec.Cmd) error {
	cmd := commandFactory(binaryPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Start the new process
	err := cmd.Start()
	if err != nil {
		return fmt.Errorf("unable to start the application: %w", err)
	}

	// Exit the current process after starting the new one
	os.Exit(0)

	return nil
}