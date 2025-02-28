package service

import (
	"fmt"
	"hyperservice-control-plane/internal/infrastructure"
	"log"
	"os"
	"os/exec"
	"strings"
)

// Função que realiza a substituição das variáveis, faz o build da imagem Docker e aplica o manifesto no Kubernetes
func ServeService(name string, imageName, podName string, policies []string, envVars map[string]string) error {
	// Debug: Exibir as variáveis recebidas
	log.Printf("DEBUG: Received parameters - name: %s, imageName: %s,  podName: %s", name, imageName, podName)
	log.Println("DEBUG: Policies received:")
	for _, policy := range policies {
		log.Println(policy)
	}
	log.Println("DEBUG: Env vars received:")
	for _, envVar := range envVars {
		log.Println(envVar)
	}

	clientset, err := infrastructure.GetKubernetesClientSet("hyperservice")
	if err != nil {
		return err
	}

	if podName == "" {
		podName = name
	}
	configPath := os.Getenv("HY_CP_CONFIG")
	if configPath == "" {
		configPath = "/etc/hy-cp"
	}
	// Definir o caminho do arquivo YAML
	yamlFilePath := configPath + "/manifests/service/serve.yaml"
	log.Printf("DEBUG: Reading YAML file from path: %s", yamlFilePath)

	// Ler o conteúdo do arquivo YAML
	yamlContent, err := os.ReadFile(yamlFilePath)
	if err != nil {
		log.Printf("ERROR: Failed to read YAML file: %v", err)
		return err
	}

	// Debug: Exibir o conteúdo do YAML antes da substituição
	log.Printf("DEBUG: Original YAML content:\n%s", string(yamlContent))

	// Defina as variáveis que você deseja substituir no YAML
	variables := map[string]string{
		"serviceName": name,
		"serve":       "true",
		"podName":     podName,
		"imageName":   imageName,
		"namespace":   "hyperservice",
	}

	// Substituir as variáveis no conteúdo YAML
	updatedYaml, err := replaceVariables(yamlContent, variables)
	if err != nil {
		log.Printf("ERROR: Failed to replace variables in YAML: %v", err)
		return err
	}

	// Debug: Exibir o YAML atualizado
	log.Printf("DEBUG: Updated YAML content after variable substitution:\n%s", string(updatedYaml))

	// Aplicar o manifesto diretamente no Kubernetes usando kubectl
	log.Printf("DEBUG: Applying updated manifest to Kubernetes using kubectl apply -f -")

	infrastructure.ApplyKubernetsEnvVars(clientset, envVars, "hyperservice-svc-"+name+"-env-var", "hyperservice")

	cmd := exec.Command("kubectl", "apply", "-f", "-") // O "-" indica que vamos passar o YAML via stdin
	cmd.Stdin = strings.NewReader(string(updatedYaml)) // Passar o YAML atualizado via stdin
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to apply manifest to Kubernetes: %v", err)
		log.Printf("Kubernetes output: %s", output)
		return err
	}

	log.Printf("DEBUG: Successfully applied the updated manifest to Kubernetes: \n%s", output)

	if err := infrastructure.ApplyKubernetesManifestsDir(configPath+"/manifests/service/policies", variables); err != nil {
		fmt.Printf("Error: %v\n", err)
	}

	if err := infrastructure.ApplyKubernetesManifests(policies, variables); err != nil {
		fmt.Printf("Error: %v\n", err)
	}

	infrastructure.DeletePodsByLabel(clientset, "hyperservice", "app="+name)

	return nil
}
