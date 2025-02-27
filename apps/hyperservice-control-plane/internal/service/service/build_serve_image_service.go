package service

import (
	"log"
	"os"
	"os/exec"
	"strings"
)

// BuildServeImageService builds and imports a service Docker image into k3d.
// It constructs the base image (if needed) and then builds the final service image.
//
// Parameters:
// - name: The name of the service (not currently used).
// - workdir: The working directory where the build context is located.
// - serviceImageName: The final image name to be built and imported into k3d.
// - baseImageName: An optional base image name; if empty, a default image is used.
//
// Returns:
// - error: Returns an error if any step in the process fails.
func BuildServeImageService(name string, workdir string, serviceImageName string, baseImageName string) error {

	// Retrieve the configuration path from the environment variable
	configPath := os.Getenv("HY_CP_CONFIG")
	if configPath == "" {
		configPath = "/etc/hy-cp"
	}

	// Define the path to the Dockerfile
	dockerfilePath := configPath + "/dockerfile/service/start/Dockerfile"
	log.Printf("DEBUG: Using Dockerfile: %s", dockerfilePath)

	var internalBaseImage string

	// If no custom base image is provided, build the default service base image
	if baseImageName == "" {
		internalBaseImage = "hyperservice-service-image:latest"
		log.Printf("INFO: No base image provided, building default service base image: %s", internalBaseImage)

		buildCmd := exec.Command("docker", "build", "-f", dockerfilePath, "-t", internalBaseImage, ".")
		log.Printf("Executing command: %s", strings.Join(buildCmd.Args, " "))

		buildOutput, err := buildCmd.CombinedOutput()
		if err != nil {
			log.Printf("ERROR: Failed to build default service base image: %v", err)
			log.Printf("Docker build output:\n%s", buildOutput)
			return err
		}

	} else {
		// If a custom base image is provided, build an image based on it
		internalBaseImage = "hyperservice-custom-service-image-" + baseImageName
		log.Printf("INFO: Using custom base image: %s", baseImageName)

		buildCmd := exec.Command("docker", "buildx", "build", "--no-cache",
			"--build-arg", "BASE_IMAGE="+baseImageName,
			"-f", dockerfilePath, "-t", internalBaseImage, ".")

		log.Printf("Executing command: %s", strings.Join(buildCmd.Args, " "))

		buildOutput, err := buildCmd.CombinedOutput()
		if err != nil {
			log.Printf("ERROR: Failed to build custom service image: %v", err)
			log.Printf("Docker build output:\n%s", buildOutput)
			return err
		}
	}

	// Build the final service image using the determined base image
	log.Printf("INFO: Building final service image: %s", serviceImageName)

	// Define the path to the Dockerfile
	dockerfilePath = configPath + "/dockerfile/service/serve/Dockerfile"
	log.Printf("DEBUG: Using Dockerfile: %s", dockerfilePath)

	buildCmd := exec.Command("docker", "buildx", "build",
		"--build-arg", "BASE_IMAGE="+internalBaseImage,
		"-f", dockerfilePath, "-t", serviceImageName, workdir)

	log.Printf("Executing command: %s", strings.Join(buildCmd.Args, " "))

	buildOutput, err := buildCmd.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to build service image: %v", err)
		log.Printf("Docker build output:\n%s", buildOutput)
		return err
	}

	// Import the built image into k3d
	log.Printf("INFO: Importing service image into k3d cluster: hyperservice")

	importCmd := exec.Command("k3d", "image", "import", serviceImageName, "--cluster", "hyperservice")
	importOutput, err := importCmd.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to import Docker image into k3d: %v", err)
		log.Printf("Import command output:\n%s", importOutput)
		return err
	}

	log.Printf("SUCCESS: Docker image '%s' successfully built and imported into k3d!", serviceImageName)

	return nil
}
