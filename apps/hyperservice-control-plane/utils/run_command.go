package utils

import (
	"fmt"
	"os/exec"
)

func RunCommand(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to execute command '%s %v': %w\nOutput: %s", command, args, err, string(output))
	}
	fmt.Printf("Output: %s\n", string(output))
	return nil
}