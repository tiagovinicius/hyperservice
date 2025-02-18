package system

import (
	"fmt"
	"hyperservice-device-app/system/utils"
	"io"
	"net/http"
	"os"
	"os/exec"
)

// Handle file upload and update the binary
func UpdateBinaryHandler(w http.ResponseWriter, r *http.Request) {
	// Limit the upload size to 50MB (adjust as needed)
	const maxUploadSize = 50 << 20

	// Parse the multipart form data (file upload)
	err := r.ParseMultipartForm(maxUploadSize)
	if err != nil {
		http.Error(w, "Unable to parse form", http.StatusBadRequest)
		return
	}

	// Get the file from the form
	file, _, err := r.FormFile("binary")
	if err != nil {
		http.Error(w, "Error retrieving file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Determine the current binary file path
	currentBinaryPath, err := os.Executable()
	if err != nil {
		http.Error(w, "Unable to get current executable path", http.StatusInternalServerError)
		return
	}

	// Create a temporary file to store the uploaded binary
	tempFile, err := os.CreateTemp("", "update-*")
	if err != nil {
		http.Error(w, "Unable to create temporary file", http.StatusInternalServerError)
		return
	}
	defer os.Remove(tempFile.Name())

	// Copy the uploaded file into the temporary file
	_, err = io.Copy(tempFile, file)
	if err != nil {
		http.Error(w, "Error saving the binary", http.StatusInternalServerError)
		return
	}

	// Replace the current executable with the uploaded binary
	err = os.Rename(tempFile.Name(), currentBinaryPath)
	if err != nil {
		http.Error(w, "Error replacing the binary", http.StatusInternalServerError)
		return
	}

	// Restart the app using the RestartApplication function from utils
	err = utils.RestartApplication(currentBinaryPath, exec.Command)
	if err != nil {
		http.Error(w, "Error restarting the application", http.StatusInternalServerError)
		return
	}

	// Respond to the client
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Successfully updated and restarting the application...\n")
}