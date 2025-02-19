package service

import (
	"context"
	"fmt"
	"log"
	"os/exec"
	"strings"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/network"
	"github.com/docker/docker/client"
	"hyperservice-control-plane/utils"
)

// StartNetwork manages the lifecycle of a Docker network using the Docker Go SDK.
func StartNetwork(name string) error {
	// Initialize the Docker client
	log.Println("DEBUG: Initializing Docker client...")
	cli, err := client.NewClientWithOpts(client.WithVersion("1.41"))
	if err != nil {
		log.Printf("ERROR: Failed to create Docker client: %v\n", err)
		return utils.LogError("failed to create Docker client", err)
	}

	// Dynamically generate the network name
	networkName := fmt.Sprintf("%s-network", name)

	// First, remove the existing network (if it exists)
	err = removeNetwork(cli, networkName)
	if err != nil {
		log.Printf("ERROR: Failed to remove network '%s': %v\n", networkName, err)
		return err
	}

	// Then, create the new network
	err = createNetwork(cli, networkName)
	if err != nil {
		log.Printf("ERROR: Failed to create network '%s': %v\n", networkName, err)
		return err
	}

	// Connect the DevContainer to the network
	log.Println("DEBUG: Retrieving host container hostname...")
	hostname, err := getHostname()
	if err != nil {
		log.Printf("ERROR: Failed to get host container hostname: %v\n", err)
		return utils.LogError("failed to get host container hostname", err)
	}

	log.Printf("DEBUG: Connecting DevContainer '%s' to '%s'...\n", hostname, networkName)
	cli, err = client.NewClientWithOpts(client.WithVersion("1.41"))
	if err != nil {
		log.Printf("ERROR: Failed to create Docker client: %v\n", err)
		return utils.LogError("failed to create Docker client", err)
	}

	if err := cli.NetworkConnect(context.Background(), networkName, hostname, nil); err != nil {
		log.Printf("ERROR: Failed to connect DevContainer to network '%s': %v\n", networkName, err)
		return utils.LogError("failed to connect DevContainer to network", err)
	}
	log.Printf("DEBUG: DevContainer '%s' connected to '%s'.\n", hostname, networkName)

	return nil
}

// removeNetwork disconnects all containers from the network and removes the network.
func removeNetwork(cli *client.Client, networkName string) error {
	// Check if the network exists
	log.Printf("DEBUG: Inspecting network '%s'...\n", networkName)
	_, err := cli.NetworkInspect(context.Background(), networkName, types.NetworkInspectOptions{})
	if err == nil {
		log.Printf("DEBUG: Network '%s' found. Removing the network...\n", networkName)
	} else if client.IsErrNotFound(err) {
		log.Printf("DEBUG: Network '%s' does not exist.\n", networkName)
		return nil
	} else {
		log.Printf("ERROR: Failed to inspect network '%s': %v\n", networkName, err)
		return utils.LogError("failed to inspect network", err)
	}

	// Disconnect containers from the network and stop them
	log.Printf("DEBUG: Retrieving containers connected to network '%s'...\n", networkName)
	containers, err := getContainersInNetwork(cli, networkName)
	if err != nil {
		log.Printf("DEBUG: Containers not connect in network '%s': %v\n", networkName, err)
		return nil
	}

	for _, container := range containers {
		log.Printf("DEBUG: Disconnecting container '%s' from network '%s'...\n", container, networkName)
		if err := cli.NetworkDisconnect(context.Background(), networkName, container, true); err != nil {
			log.Printf("ERROR: Failed to disconnect container '%s': %v\n", container, err)
			return utils.LogError(fmt.Sprintf("failed to disconnect container '%s'", container), err)
		}
	}

	// Remove the network
	log.Printf("DEBUG: Removing network '%s'...\n", networkName)
	if err := cli.NetworkRemove(context.Background(), networkName); err != nil {
		log.Printf("ERROR: Failed to remove network '%s': %v\n", networkName, err)
		return utils.LogError(fmt.Sprintf("failed to remove network '%s'", networkName), err)
	}
	log.Printf("DEBUG: Network '%s' removed successfully.\n", networkName)

	return nil
}

// createNetwork creates a new Docker network with the specified name.
func createNetwork(cli *client.Client, networkName string) error {
	log.Printf("DEBUG: Creating new network '%s'...\n", networkName)
	_, err := cli.NetworkCreate(context.Background(), networkName, types.NetworkCreate{
		Driver: "bridge", // Use the "bridge" driver for the network
		IPAM: &network.IPAM{ // Correct usage of IPAM struct
			Config: []network.IPAMConfig{
				{Subnet: "192.168.1.0/24", Gateway: "192.168.1.1"},
			},
		},
	})
	if err != nil {
		log.Printf("ERROR: Failed to create network '%s': %v\n", networkName, err)
		return utils.LogError(fmt.Sprintf("failed to create network '%s'", networkName), err)
	}
	log.Printf("DEBUG: Network '%s' created successfully.\n", networkName)

	return nil
}

// getContainersInNetwork retrieves all containers connected to a specific network.
func getContainersInNetwork(cli *client.Client, networkName string) ([]string, error) {
	containers := []string{}
	log.Printf("DEBUG: Inspecting network '%s' to get containers...\n", networkName)
	network, err := cli.NetworkInspect(context.Background(), networkName, types.NetworkInspectOptions{})
	if err != nil {
		log.Printf("ERROR: Failed to inspect network '%s': %v\n", networkName, err)
		return nil, utils.LogError(fmt.Sprintf("failed to inspect network '%s'", networkName), err)
	}

	for containerID := range network.Containers {
		containers = append(containers, containerID)
	}
	return containers, nil
}

// getHostname retrieves the hostname of the DevContainer.
func getHostname() (string, error) {
	log.Println("DEBUG: Executing hostname command...")
	hostname, err := exec.Command("hostname").Output()
	if err != nil {
		log.Printf("ERROR: Failed to get hostname: %v\n", err)
		return "", utils.LogError("failed to get hostname", err)
	}
	return strings.TrimSpace(string(hostname)), nil
}