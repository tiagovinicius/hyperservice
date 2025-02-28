package infrastructure

import (
	"fmt"
	"os/exec"
	"strings"
)

func CheckK3dNodeExists(nodeName string) bool {
	cmd := exec.Command("k3d", "node", "list")
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(output), nodeName)
}

func CreateK3dNode(nodeName string) error {
	cmd := exec.Command("k3d", "node", "create", nodeName)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create node %s: %w", nodeName, err)
	}
	return nil
}
