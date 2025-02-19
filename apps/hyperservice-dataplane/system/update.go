package system

import (
	"fmt"
	"hyperservice-dataplane/system/utils"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"
)

// Handle file upload and update the binary
func UpdateBinaryHandler(w http.ResponseWriter, r *http.Request) {
	const maxUploadSize = 50 << 20 // 50MB limit

	// Parse the form data
	err := r.ParseMultipartForm(maxUploadSize)
	if err != nil {
		log.Printf("Error parsing form: %v", err)
		http.Error(w, "Unable to parse form", http.StatusBadRequest)
		return
	}

	// Get the file from the form
	file, _, err := r.FormFile("binary")
	if err != nil {
		log.Printf("Error retrieving file: %v", err)
		http.Error(w, "Error retrieving file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Determine the current binary file path
	currentBinaryPath, err := os.Executable()
	if err != nil {
		log.Printf("Error getting current executable path: %v", err)
		http.Error(w, "Unable to get current executable path", http.StatusInternalServerError)
		return
	}

	// Create a temporary file in the default system temporary directory
	tempFile, err := os.CreateTemp("/tmp", "update-*")
	if err != nil {
		log.Printf("Error creating temporary file: %v", err)
		http.Error(w, "Unable to create temporary file", http.StatusInternalServerError)
		return
	}
	defer os.Remove(tempFile.Name())

	// Copy the uploaded file into the temporary file
	_, err = io.Copy(tempFile, file)
	if err != nil {
		log.Printf("Error saving the binary: %v", err)
		http.Error(w, "Error saving the binary", http.StatusInternalServerError)
		return
	}

	// Try to rename the current binary to a backup
	backupBinaryPath := currentBinaryPath + ".bak"
	err = os.Rename(currentBinaryPath, backupBinaryPath)
	if err != nil {
		log.Printf("Error renaming the current binary: %v", err)
		http.Error(w, "Error backing up current binary", http.StatusInternalServerError)
		return
	}

	// Replace the current binary with the uploaded binary
	err = utils.CopyFile(tempFile.Name(), currentBinaryPath)
	if err != nil {
		log.Printf("Error replacing the binary: %v", err)
		http.Error(w, "Error replacing the binary", http.StatusInternalServerError)
		return
	}

	// Set the correct permissions to make the binary executable
	err = os.Chmod(currentBinaryPath, 0755) // Grant execute permissions
	if err != nil {
		log.Printf("Error setting execute permissions: %v", err)
		http.Error(w, "Error setting execute permissions", http.StatusInternalServerError)
		return
	}

	// Log success and notify the client
	log.Printf("Successfully updated the binary. Restarting the application...")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Successfully updated the binary. The application will now restart...\n")

	// Restart the app asynchronously in the background
	go func() {
		// Wait a little to make sure the response has been sent
		time.Sleep(1 * time.Second)

		// Restart the application using the RestartApplication function from utils
		err = utils.RestartApplication(currentBinaryPath, exec.Command)
		if err != nil {
			log.Printf("Error restarting the application: %v", err)
		}
	}()
}
