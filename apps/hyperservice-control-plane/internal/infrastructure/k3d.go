package infrastructure

import (
	"bytes"
	"fmt"
	"hyperservice-control-plane/internal/infrastructure/model"
	"log"
	"os"
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

func CreateK3DCluster(clusterName string, hostWorkspacePath, devWorkspacePath string) error {
	// Step 1: Create the cluster with only the server
	cmdArgs := []string{
		"cluster", "create", clusterName,
		"--no-lb",
		"--servers", "1",
		"--api-port", "6443",
		"--network", "hyperservice-network",
		"--volume", "hyperservice-grafana-data:/var/lib/grafana",
		"--volume", "/var/run/docker.sock:/var/run/docker.sock",
		"--volume", hostWorkspacePath + ":" + devWorkspacePath,
	}

	fmt.Printf("🚀 Executing k3d cluster create: k3d %v\n", cmdArgs)
	cmd := exec.Command("k3d", cmdArgs...)
	cmdOutput := &bytes.Buffer{}
	cmd.Stdout = cmdOutput
	cmd.Stderr = cmdOutput

	if err := cmd.Run(); err != nil {
		fmt.Printf("❌ Failed to create k3d cluster: %v\nOutput:\n%s\n", err, cmdOutput.String())
		return fmt.Errorf("failed to create k3d cluster: %w", err)
	}

	fmt.Printf("✅ K3D cluster created successfully with server only!\nOutput:\n%s\n", cmdOutput.String())
	return nil
}

func CreateK3dNodes(clusterName string, agents []model.ClusterNode) error {
	// Step 2: Retrieve the K3S token from the server container
	serverContainerName := "k3d-" + clusterName + "-server-0"
	cmdGetToken := exec.Command("docker", "exec", serverContainerName, "cat", "/var/lib/rancher/k3s/server/node-token")
	tokenOutput, err := cmdGetToken.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to retrieve K3S token from server container: %v\n", err)
		log.Printf("Command output:\n%s\n", tokenOutput)
		return err
	}
	k3sToken := strings.TrimSpace(string(tokenOutput))

	// Step 4: Dynamically add agents
	for _, agent := range agents {
		if !agent.GetSimulate() {
			fmt.Printf("⚠️ Skipping agent %s as Simulate is not true\n", agent.GetName())
			continue
		}

		agentName := agent.GetName()
		image := agent.GetImage()

		configPath := os.Getenv("HY_CP_CONFIG")
		if configPath == "" {
			configPath = "/etc/hy-cp"
		}

		dockerfilePath := configPath + "/dockerfile/node/Dockerfile"
		log.Printf("DEBUG: Using Dockerfile: %s", dockerfilePath)

		internalImage := "hyperservice-node-image-" + agentName + "-" + image
		if image == "" {
			internalImage = "hyperservice-node-image-" + agentName
		}
		log.Printf("INFO: Building node image: %s", internalImage)

		buildCmd := exec.Command("docker", "buildx", "build", "--no-cache",
			"--build-arg", "BASE_IMAGE="+image,
			"--build-arg", "K3S_TOKEN="+k3sToken,
			"--build-arg", "K3S_URL=https://k3d-hyperservice-server-0:6443",
			"-f", dockerfilePath, "-t", internalImage, ".")

		buildOutput, err := buildCmd.CombinedOutput()
		if err != nil {
			log.Printf("ERROR: Failed to build default node image: %v", err)
			log.Printf("Docker build output:\n%s", buildOutput)
			return err
		}

		log.Printf("SUCCESS: Docker image '%s' successfully built and imported into k3d!", internalImage)
		// internalImage is already specified in the docker run command above, no need to append.

		// Step 4.1: Remove existing container if present
		existingContainerCmd := exec.Command("docker", "rm", "-f", "k3d-"+clusterName+"-"+agentName)
		existingContainerOutput, err := existingContainerCmd.CombinedOutput()
		if err != nil {
			log.Printf("INFO: No existing container to remove: %s\n", agentName)
		} else {
			log.Printf("INFO: Existing container removed: %s\nOutput:\n%s\n", agentName, existingContainerOutput)
		}

		fmt.Printf("🔍 Adding agent %s\n", agentName)
		agentArgs := []string{
			"node", "create", clusterName + "-" + agentName,
			"--role", "agent",
			"--network", "hyperservice-network",
			"--cluster", clusterName,
			"--image", internalImage,
		}
		cmd := exec.Command("k3d", agentArgs...)
		cmdOutput := &bytes.Buffer{}
		cmd.Stdout = cmdOutput
		cmd.Stderr = cmdOutput

		if err := cmd.Run(); err != nil {
			fmt.Printf("❌ Failed to add agent %s: %v\nOutput:\n%s\n", agentName, err, cmdOutput.String())
			return fmt.Errorf("failed to add agent %s: %w", agentName, err)
		}
		

		fmt.Printf("✅ Agent %s added successfully!\nOutput:\n%s\n", agentName, cmdOutput.String())
	}

	fmt.Println("🎯 All agents added successfully!")
	return nil
}
