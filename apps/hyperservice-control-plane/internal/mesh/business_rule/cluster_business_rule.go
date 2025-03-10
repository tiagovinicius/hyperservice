package business_rule

import (
	"context"
	"encoding/json"
	"fmt"
	"hyperservice-control-plane/internal/infrastructure"
	"hyperservice-control-plane/internal/mesh/model"
	"os"
	"os/exec"

	k3dModel "hyperservice-control-plane/internal/infrastructure/model"

	"github.com/docker/docker/api/types/volume"
	dockerClient "github.com/docker/docker/client"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/util/retry"
)

func CreateCluster(clusterName string) error {
	hostWorkspacePath := os.Getenv("HYPERSERVICE_DEV_HOST_WORKSPACE_PATH")
	devWorkspacePath := os.Getenv("HYPERSERVICE_DEV_WORKSPACE_PATH")

	if devWorkspacePath == "" {
		return fmt.Errorf("HYPERSERVICE_DEV_WORKSPACE_PATH is not set")
	}
	if hostWorkspacePath == "" {
		hostWorkspacePath = devWorkspacePath
	}

	err := infrastructure.CreateK3DCluster(clusterName, hostWorkspacePath, devWorkspacePath)
	if err != nil {
		fmt.Printf("❌ Failed to create K3D cluster: %v\n", err)
		return err
	}

	return nil
}

func CreateNodes(clusterName string, cluster *[]model.ClusterNode) error {
	if err := WaitForClusterReadiness(clusterName); err != nil {
		fmt.Printf("Error checking Cluter liveness: %v\n", err)
		return err
	}

	fmt.Println("✅ K3D cluster created successfully!")


	var nodes []k3dModel.ClusterNode
	for _, node := range *cluster {
		nodes = append(nodes, &node)
	}

	err := infrastructure.CreateK3dNodes(clusterName, nodes)
	if err != nil {
		fmt.Printf("❌ Failed to create K3D nodes: %v\n", err)
		return err
	}

	return nil
}

// ensureVolumeExists checks if a Docker volume exists, and creates it if not
func EnsureVolumeExists(volumeName string) error {
	// Create a Docker client
	cli, err := dockerClient.NewClientWithOpts(dockerClient.FromEnv)
	if err != nil {
		return fmt.Errorf("failed to create Docker client: %w", err)
	}

	// Check if the volume exists
	volumes, err := cli.VolumeList(context.Background(), volume.ListOptions{})
	if err != nil {
		return fmt.Errorf("failed to list Docker volumes: %w", err)
	}

	// Check if the volume is in the list
	for _, vol := range volumes.Volumes {
		if vol.Name == volumeName {
			fmt.Printf("✅ Volume '%s' already exists.\n", volumeName)
			return nil
		}
	}

	// If the volume doesn't exist, create it
	fmt.Printf("⏳ Volume '%s' does not exist, creating...\n", volumeName)
	_, err = cli.VolumeCreate(context.Background(), volume.CreateOptions{
		Name: volumeName,
	})
	if err != nil {
		return fmt.Errorf("failed to create volume %s: %w", volumeName, err)
	}
	fmt.Printf("✅ Volume '%s' created successfully!\n", volumeName)

	return nil
}

// getExistingClusters retrieves the list of existing clusters using the K3D binary
func GetExistingClusters() ([]string, error) {
	// Build the K3D command to list clusters
	cmd := exec.Command("k3d", "cluster", "list", "-o", "json")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("failed to list existing clusters: %w", err)
	}

	// Parse the output (for simplicity, assuming JSON format)
	var clusters []struct {
		Name string `json:"name"`
	}
	if err := json.Unmarshal(output, &clusters); err != nil {
		return nil, fmt.Errorf("failed to parse JSON output: %w", err)
	}

	// Create a slice with just the cluster names
	var clusterNames []string
	for _, cluster := range clusters {
		clusterNames = append(clusterNames, cluster.Name)
	}

	// Return the cluster names
	return clusterNames, nil
}

// deleteCluster deletes a k3d cluster using the K3D binary
func DeleteCluster(clusterName string) error {
	// Build the K3D command to delete the cluster
	cmd := exec.Command("k3d", "cluster", "delete", clusterName)
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to delete cluster '%s': %w", clusterName, err)
	}

	// Successfully deleted the cluster
	return nil
}

// waitForK8SAPI waits for the Kubernetes API to be ready using client-go SDK
func GetClusterReadiness(clusterName string) error {
	// Get Kubernetes client
	clientset, err := infrastructure.GetKubernetesClientSet(clusterName)
	if err != nil {
		return err
	}

	// Check if Kubernetes API is accessible
	_, err = clientset.Discovery().ServerVersion()
	if err != nil {
		return fmt.Errorf("kubernetes API is not ready yet: %w", err)
	}

	// Check if the nodes are accessible
	_, err = clientset.CoreV1().Nodes().List(context.Background(), metav1.ListOptions{})
	if err != nil {
		return fmt.Errorf("❌ ERROR: Kubernetes nodes are not accessible: %w", err)
	}

	return nil

}

// waitForK8SAPI waits for the Kubernetes API to be ready using client-go SDK
func WaitForClusterReadiness(clusterName string) error {
	// Retry logic to wait for API
	return retry.OnError(retry.DefaultRetry, func(err error) bool {
		// We retry if the pod is not in running state
		return true
	}, func() error {
		err := GetClusterReadiness(clusterName)
		if err != nil {
			return fmt.Errorf("kubernetes API is not ready yet: %w", err)
		}
		return nil
	})
}

func CreateApplicationsNamespace(clusterName string, namespace string) error {
	// Get Kubernetes client
	clientset, err := infrastructure.GetKubernetesClientSet(clusterName)
	if err != nil {
		return err
	}

	fmt.Printf("⚙️ Creating '%s' namespace...\n", clusterName)
	if err := infrastructure.CreateKubernetesNamespace(clientset, namespace); err != nil {
		return err
	}

	return nil
}
