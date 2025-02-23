package infrastructure

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"hyperservice-control-plane/utils"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	dockerClient "github.com/docker/docker/client"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/api/core/v1"
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

	if !checkKubeConfig() {
		fmt.Println("Kubeconfig not found, generating it...")
		err := generateKubeConfig(clusterName)
		if err != nil {
			return nil, fmt.Errorf("failed to generate kubeconfig: %v", err)
		}
	}

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
	_, err := clientset.CoreV1().Namespaces().Get(context.Background(), namespace, metav1.GetOptions{})
	if err == nil {
		fmt.Printf("✅ Namespace '%s' already exists, skipping creation.\n", namespace)
		return nil
	}

	ns := &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name: namespace,
		},
	}

	_, err = clientset.CoreV1().Namespaces().Create(context.Background(), ns, metav1.CreateOptions{})
	if err != nil {
		return fmt.Errorf("failed to create namespace '%s': %w", namespace, err)
	}

	fmt.Printf("✅ Namespace '%s' created successfully.\n", namespace)
	return nil
}

func MakeKubernetesPortForward(namespace string, serviceName string, localPort string, remotePort string) error {
	err := utils.KillProcessOnPort(localPort)
	if err != nil {
		return fmt.Errorf("failed to ensure port is free: %w", err)
	}

	cmd := exec.Command("kubectl", "port-forward", "-n", namespace, fmt.Sprintf("svc/%s", serviceName), fmt.Sprintf("%s:%s", localPort, remotePort))

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

// checkKubeConfig checks if the kubeconfig file exists
func checkKubeConfig() bool {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Println("Error getting user home directory:", err)
		return false
	}

	kubeConfigPath := filepath.Join(homeDir, ".kube", "config")
	_, err = os.Stat(kubeConfigPath)
	return !os.IsNotExist(err)
}

// generateKubeConfig generates the kubeconfig if it does not exist
func generateKubeConfig(clusterName string) error {
	cmd := exec.Command("k3d", "kubeconfig", "get", clusterName)
	kubeconfig, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to get kubeconfig: %v", err)
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get user home directory: %w", err)
	}

	kubeConfigPath := filepath.Join(homeDir, ".kube", "config")
	err = os.MkdirAll(filepath.Dir(kubeConfigPath), os.ModePerm)
	if err != nil {
		return fmt.Errorf("failed to create .kube directory: %w", err)
	}

	err = os.WriteFile(kubeConfigPath, kubeconfig, 0600)
	if err != nil {
		return fmt.Errorf("failed to write kubeconfig to %s: %v", kubeConfigPath, err)
	}

	fmt.Println("Kubeconfig generated and saved to:", kubeConfigPath)
	return nil
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

// deleteResource deletes a Kubernetes resource by type and name.
func DeleteKubernetsResource(resourceType, label, namespace string) {
	RunKubernetsCommand("delete", resourceType, "-n", namespace, "-l", label, "--ignore-not-found")
}

// RunKubernetsCommand runs a kubectl command with the given arguments.
func RunKubernetsCommand(args ...string) {
	cmd := exec.Command("kubectl", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("❌ Error running kubectl command: %v\n", err)
	}
}

// runDockerCommand runs a docker command with the given arguments.
func RunDockerCommand(nodeName, command string) {
	cmd := exec.Command("docker", "exec", nodeName, "sh", "-c", command)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("❌ Error running docker command: %v\n", err)
	}
}

// ApplyKubernetesManifestsDir applies Kubernetes manifests from a given directory and substitutes variables with provided values.
func ApplyKubernetesManifestsDir(workspacePath string, substitutions map[string]string) error {
	// Get all YAML files in the directory
	yamlFiles, err := getYamlFiles(workspacePath)
	if err != nil {
		return err
	}

	// Ensure there is at least one policy file
	if len(yamlFiles) == 0 {
		fmt.Printf("⚠️ No policy files found in %s", workspacePath)
		return nil
	}

	// Apply remaining policies, excluding mesh.yml
	for _, file := range yamlFiles {
		fmt.Printf("📄 Applying policy: %s\n", file)
		err = applyK8sManifest(file, substitutions)
		if err != nil {
			fmt.Errorf("⚠️ Policy file %s was not applied: %w", file, err)
		}
	}

	return nil
}

// getYamlFiles retrieves all .yml files in the given directory, sorted.
func getYamlFiles(dir string) ([]string, error) {
	var files []string
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".yml") {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	// Sort files alphabetically
	sort.Strings(files)
	return files, nil
}

// fileExists checks if a file exists.
func fileExists(filename string) bool {
	_, err := os.Stat(filename)
	return !os.IsNotExist(err)
}

// applyK8sManifest applies a Kubernetes manifest using kubectl, with variable substitution.
func applyK8sManifest(file string, substitutions map[string]string) error {
	// Read the file content using os.ReadFile (since ioutil is deprecated)
	content, err := os.ReadFile(file)
	if err != nil {
		return fmt.Errorf("failed to read file %s: %v", file, err)
	}

	// Substitute environment variables and custom variables in the content
	envSubstitutedContent := os.ExpandEnv(string(content))

	// Substitute custom variables from the map
	for key, value := range substitutions {
		// Replace variables in the form of {{key}} with their corresponding value
		envSubstitutedContent = strings.ReplaceAll(envSubstitutedContent, fmt.Sprintf("{{%s}}", key), value)
	}

	// Create a temporary buffer for kubectl input
	var kubectlInput bytes.Buffer
	kubectlInput.WriteString(envSubstitutedContent)

	// Execute kubectl apply command
	cmd := exec.Command("kubectl", "apply", "-f", "-")
	cmd.Stdin = &kubectlInput
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to apply manifest %s: %v", file, err)
	}

	return nil
}

// DeletePodsByLabel removes all pods matching a given label selector in a specified namespace.
func DeletePodsByLabel(clientset *kubernetes.Clientset, namespace, labelSelector string) {
	pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: labelSelector,
	})
	if err != nil {
		fmt.Printf("⚠️ Error listing pods: %v\n", err)
		return
	}

	if len(pods.Items) == 0 {
		fmt.Println("✅ No pods found matching the given label selector.")
		return
	}

	for _, pod := range pods.Items {
		fmt.Printf("🗑️ Deleting pod: %s...\n", pod.Name)
		err := clientset.CoreV1().Pods(namespace).Delete(context.TODO(), pod.Name, metav1.DeleteOptions{})
		if err != nil {
			fmt.Printf("⚠️ Failed to delete pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Pod %s deleted successfully.\n", pod.Name)
		}
	}
}

// ApplyKubernetsEnvVar recebe um clientset, lê um arquivo .env e aplica como ConfigMap no Kubernetes
func ApplyKubernetsEnvVar(clientset *kubernetes.Clientset, envFilePath, configName string, namespace string) error {
	// Ler as variáveis do .env e armazená-las em um map
	envData := make(map[string]string)

	file, err := os.Open(envFilePath)
	if err != nil {
		fmt.Println("Could not find or open .env file: %w", err)
		return nil
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue // Ignorar linhas vazias e comentários
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])
			envData[key] = value
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Println("❌ error reading .env file: %w", err)
		return nil
	}

	// Criar o objeto ConfigMap
	configMap := &v1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      configName,
			Namespace: namespace,
		},
		Data: envData,
	}

	// Aplicar o ConfigMap no cluster
	existingConfigMap, err := clientset.CoreV1().ConfigMaps(namespace).Get(context.TODO(), configMap.Name, metav1.GetOptions{})
	if err == nil {
		// Se já existe, atualizar
		configMap.ResourceVersion = existingConfigMap.ResourceVersion // Necessário para Update
		_, err = clientset.CoreV1().ConfigMaps(namespace).Update(context.TODO(), configMap, metav1.UpdateOptions{})
		if err != nil {
			return fmt.Errorf("❌ error updating ConfigMap: %w", err)
		}
		fmt.Println("✅ ConfigMap updated successfully!")
	} else {
		// Se não existe, criar um novo
		_, err = clientset.CoreV1().ConfigMaps(namespace).Create(context.TODO(), configMap, metav1.CreateOptions{})
		if err != nil {
			return fmt.Errorf("❌ error creating ConfigMap: %w", err)
		}
		fmt.Println("✅ ConfigMap created successfully!")
	}
	return nil
}
