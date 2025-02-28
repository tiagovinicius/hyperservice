package service

import (
	"fmt"
	"hyperservice-control-plane/internal/infrastructure"
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
func StartService(name string, workdir string, imageName, podName string, policies []string, envVars map[string]string) error {
	// Debug: Exibir as variáveis recebidas
	log.Printf("DEBUG: Received parameters - name: %s, workdir: %s, imageName: %s,  podName: %s", name, workdir, imageName, podName)
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

	configPath := os.Getenv("HY_CP_CONFIG")
	if configPath == "" {
		configPath = "/etc/hy-cp"
	}

	dockerfilePath := configPath + "/dockerfile/service/start/Dockerfile"
	log.Printf("DEBUG: Building Docker image from Dockerfile: %s", dockerfilePath)
	if imageName == "" {
		imageName = "hyperservice-service-image:latest"
		buildCmd := exec.Command("docker", "build", "-f", dockerfilePath, "-t", imageName, ".")
		buildOutput, err := buildCmd.CombinedOutput()
		if err != nil {
			log.Printf("ERROR: Failed to build Docker image: %v", err)
			log.Printf("Docker build output: %s", buildOutput)
			return err
		}

	} else {
		baseImage := imageName
		imageName = "hyperservice-custom-service-image-" + imageName
		buildCmd := exec.Command("docker", "buildx", "build", "--build-arg", "BASE_IMAGE="+baseImage, "-f", dockerfilePath, "-t", imageName, ".")
		log.Printf("Executing command: %s", strings.Join(buildCmd.Args, " "))
		buildOutput, err := buildCmd.CombinedOutput()
		if err != nil {
			log.Printf("ERROR: Failed to build Docker image: %v", err)
			log.Printf("Docker build output: %s", buildOutput)
			return err
		}
	}

	log.Printf("Importing image to k3d!")
	// Importando a imagem para o k3d
	importCmd := exec.Command("k3d", "image", "import", imageName, "--cluster", "hyperservice")
	importOutput, err := importCmd.CombinedOutput()
	if err != nil {
		log.Printf("ERROR: Failed to import Docker image to k3d: %v", err)
		log.Printf("Import command output: %s", importOutput)
		return err
	}

	log.Printf("Docker image successfully built and imported to k3d!")

	if podName == "" {
		podName = name
	}

	// Definir o caminho do arquivo YAML
	yamlFilePath := configPath + "/manifests/service/start.yaml"
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
		"serve":       "false",
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
