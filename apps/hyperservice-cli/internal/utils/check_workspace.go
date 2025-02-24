package utils

import (
	"fmt"
	"os"
	"path/filepath"
)

// checkWorkspace ensures the CLI is executed inside a valid hyperservice workspace
func CheckWorkspace(workdir string) {
	requiredFiles := []string{
		filepath.Join(workdir, ".prototools"),
		filepath.Join(workdir, ".moon/workspace.yml"),
	}
	requiredDirs := []string{
		filepath.Join(workdir, "apps"),
	}

	// Check for required files
	for _, file := range requiredFiles {
		if _, err := os.Stat(file); os.IsNotExist(err) {
			fmt.Printf("❌ Error: Missing required file: %s\n", file)
			os.Exit(1)
		}
	}

	// Check for required directories
	for _, dir := range requiredDirs {
		if info, err := os.Stat(dir); os.IsNotExist(err) || !info.IsDir() {
			fmt.Printf("❌ Error: Missing required directory: %s\n", dir)
			os.Exit(1)
		}
	}

	fmt.Println("✅ Workspace validation successful!")
}