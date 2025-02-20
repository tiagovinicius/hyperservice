package infrastructure

import (
	"context"
	"fmt"
	"hyperservice-control-plane/utils"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	dockerClient "github.com/docker/docker/client"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

// getKubernetesClientSet creates a Kubernetes clientset from the kube config file.
func GetKubernetesClientSet(clusterName string) (*kubernetes.Clientset, error) {
	// Get the server IP inside the "hyperservice-network" network
	serverIP, err := getControlPlaneIP(clusterName)
	if err != nil {
		return nil, err
	}
	fmt.Printf("🌍 K3s Server IP: %s\n", serverIP)

	err = updateKubeConfig(serverIP)
	if err != nil {
		return nil, fmt.Errorf("failed to build kubeconfig: %w", err)
	}

	// Get the home directory of the user
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get user home directory: %w", err)
	}

	// Construct the path to the kube config file
	kubeConfigPath := filepath.Join(homeDir, ".kube", "config")

	// Create Kubernetes client
	config, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		return nil, fmt.Errorf("failed to build kubeconfig: %w", err)
	}

	// Create the Kubernetes clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create Kubernetes client: %w", err)
	}

	return clientset, nil
}

func CreateKubernetesNamespace(clientset *kubernetes.Clientset, namespace string) error {
	// Create namespace object
	ns := &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name: namespace,
		},
	}

	// Create the namespace using clientset
	_, err := clientset.CoreV1().Namespaces().Create(context.Background(), ns, metav1.CreateOptions{})
	if err != nil {
		return fmt.Errorf("failed to create namespace '%s': %w", namespace, err)
	}

	fmt.Printf("✅ Namespace '%s' created successfully.\n", namespace)
	return nil
}

func MakeKubernetesPortForward(namespace string, serviceName string, localPort string, remotePort string) error {
	// Kill any existing process on the local port (if any)
	err := utils.KillProcessOnPort(localPort)
	if err != nil {
		return fmt.Errorf("failed to ensure port is free: %w", err)
	}

	// Prepare the kubectl port-forward command
	cmd := exec.Command("kubectl", "port-forward", "-n", namespace, fmt.Sprintf("svc/%s", serviceName), fmt.Sprintf("%s:%s", localPort, remotePort))

	// Start the process in the background using goroutine
	go func() {
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Start(); err != nil {
			fmt.Printf("Failed to start port-forwarding process: %v\n", err)
			return
		}

		// Keep the process running in the background, no need to block
		if err := cmd.Wait(); err != nil {
			fmt.Printf("Port-forwarding process exited with error: %v\n", err)
		}
	}()

	// Wait a few seconds for the port-forwarding to be established
	time.Sleep(3 * time.Second)

	// Check if the port forwarding was successful
	listen, err := net.Listen("tcp", fmt.Sprintf("localhost:%d", localPort))
	if err != nil {
		return fmt.Errorf("port-forwarding failed: %w", err)
	}
	defer listen.Close()

	fmt.Printf("✅ Port forwarding established: localhost:%s -> %s:%s\n", localPort, serviceName, remotePort)
	return nil
}

// getClusterControlPlaneIP retrieves the server IP inside the "hyperservice-network" network using Docker SDK
func getControlPlaneIP(clusterName string) (string, error) {
	// Create a Docker client
	cli, err := dockerClient.NewClientWithOpts(dockerClient.FromEnv)
	if err != nil {
		return "", fmt.Errorf("failed to create Docker client: %w", err)
	}

	// Inspect the container's network settings to get the IP address
	containerName := fmt.Sprintf("k3d-%s-server-0", clusterName)
	container, _, err := cli.ContainerInspectWithRaw(context.Background(), containerName, false)
	if err != nil {
		return "", fmt.Errorf("failed to inspect container '%s': %w", containerName, err)
	}

	// Get the IP address from the container's network settings
	serverIP := container.NetworkSettings.Networks["hyperservice-network"].IPAddress
	return serverIP, nil
}

// updateKubeConfig updates kubeconfig with the new server IP
func updateKubeConfig(serverIP string) error {
	// Get the home directory of the user
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get user home directory: %w", err)
	}

	// Construct the path to the kube config file
	kubeConfigPath := filepath.Join(homeDir, ".kube", "config")

	cmd := exec.Command("sed", "-i", fmt.Sprintf("s/0.0.0.0/%s/g", serverIP), kubeConfigPath)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to update kubeconfig: %w", err)
	}
	return nil
}
