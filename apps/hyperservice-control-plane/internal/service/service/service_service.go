package service

import (
	"fmt"
	"hyperservice-control-plane/internal/mesh/infrastructure"
	"log"
	"os"
	"os/exec"
	"strings"
)

// Função para substituir as variáveis no conteúdo YAML
func replaceVariables(yamlContent []byte, variables map[string]string) ([]byte, error) {
	// Converte o YAML para string para facilitar a substituição
	contentStr := string(yamlContent)

	// Substitui cada variável no YAML
	for key, value := range variables {
		// Substitui todas as ocorrências da variável no YAML
		placeholder := fmt.Sprintf("{{%s}}", key)
		contentStr = strings.ReplaceAll(contentStr, placeholder, value)
	}

	// Retorna o conteúdo YAML atualizado como []byte
	return []byte(contentStr), nil
}

// Função que realiza a substituição das variáveis, faz o build da imagem Docker e aplica o manifesto no Kubernetes
func StartService(name string, workdir string, podName string, policies []string) error {
	imageName := "hyperservice-service-image"
	if podName == "" {
		podName = name
	}
	// Debug: Exibir as variáveis recebidas
	log.Printf("DEBUG: Received parameters - name: %s, workdir: %s, podName: %s", name, workdir, podName)

	// Definir o caminho do arquivo YAML
	yamlFilePath := "./config/manifests/service/start.yaml"
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
		"workdir":     workdir,
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

	// **Passo 1: Build da imagem Docker**
	// Caminho para o Dockerfile
	dockerfilePath := "./config/dockerfile/service/Dockerfile"
	log.Printf("DEBUG: Building Docker image from Dockerfile: %s", dockerfilePath)

	// Construção da imagem Docker
	buildCmd := exec.Command("docker", "build", "-f", dockerfilePath, "-t", imageName, ".")
	buildOutput, err := buildCmd.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to build Docker image: %v", err)
		log.Printf("Docker build output: %s", buildOutput)
		return err
	}

	// Importando a imagem para o k3d
	importCmd := exec.Command("k3d", "image", "import", imageName, "--cluster", "hyperservice")
	importOutput, err := importCmd.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to import Docker image to k3d: %v", err)
		log.Printf("Import command output: %s", importOutput)
		return err
	}

	log.Printf("Docker image successfully built and imported to k3d!")

	// Aplicar o manifesto diretamente no Kubernetes usando kubectl
	log.Printf("DEBUG: Applying updated manifest to Kubernetes using kubectl apply -f -")

	cmd := exec.Command("kubectl", "apply", "-f", "-") // O "-" indica que vamos passar o YAML via stdin
	cmd.Stdin = strings.NewReader(string(updatedYaml)) // Passar o YAML atualizado via stdin
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to apply manifest to Kubernetes: %v", err)
		log.Printf("Kubernetes output: %s", output)
		return err
	}

	log.Printf("DEBUG: Successfully applied the updated manifest to Kubernetes: \n%s", output)

	if err := infrastructure.ApplyKubernetesManifestsDir("./config/manifests/service/policies", variables); err != nil {
		fmt.Printf("Error: %v\n", err)
	}

	if err := infrastructure.ApplyKubernetesManifestsDir(workdir + "/.hyperservice/policies", variables); err != nil {
		fmt.Printf("Error: %v\n", err)
	}

	return nil
}
