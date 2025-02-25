package utils

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// ImportRepo fetches only the repository files without git metadata
func ImportRepo(repoURL, destination string) error {
	// Remove existing cache directory to ensure a fresh export
	if err := os.RemoveAll(destination); err != nil {
		return fmt.Errorf("failed to clear cache directory: %w", err)
	}

	// Clone the repository shallowly (only the latest commit)
	cmd := exec.Command("git", "clone", "--depth=1", repoURL, destination)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to clone repository: %w", err)
	}

	// Remove the .git directory to keep only the working files
	gitDir := filepath.Join(destination, ".git")
	if err := os.RemoveAll(gitDir); err != nil {
		return fmt.Errorf("failed to remove .git directory: %w", err)
	}

	return nil
}
