package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	rootCmd "hyperservice-cli/cmd"
	"hyperservice-cli/internal/service/business_logic"
	"hyperservice-cli/internal/service/request"
	"hyperservice-cli/internal/utils"

	"github.com/spf13/cobra"
)

// serviceStartCmd represents the `observability up` command
var serviceStartCmd = &cobra.Command{
	Use:   "start <name>",
	Short: "Start a specific service",
	RunE: func(cmd *cobra.Command, args []string) error {
		serviceName := args[0]
		workdir := rootCmd.GetWorkdir()
		importFilePath := filepath.Join(workdir, "apps", serviceName, ".hyperservice", "import.yml")
		containerFilePath := filepath.Join(workdir, "apps", serviceName, ".hyperservice", "container.yml")
		clusterFilePath := filepath.Join(workdir, "apps", serviceName, ".hyperservice", "cluster.yml")
		cacheDir := filepath.Join(workdir, "apps", serviceName, ".hyperservice", "cache", "git")

		var cluster []string
		if _, err := os.Stat(clusterFilePath); err == nil {
			clusterData, err := business_logic.ReadClusterFile(clusterFilePath)
			if err != nil {
				fmt.Println("failed to read cluster file:", err)
			} else {
				cluster = clusterData.Cluster
			}
		}

		if _, err := os.Stat(importFilePath); err == nil {
			// Read container image from import.yml
			importData, err := business_logic.ReadImportFile(importFilePath)
			if err != nil {
				fmt.Println("failed to read import file: %w", err)
			}

			importWorkdir := ""
			if importData.Git != nil {
				importWorkdir = importData.Git.Workdir
				// Clone or update the repository
				if err := utils.ImportRepo(importData.Git.Url, cacheDir); err != nil {
					fmt.Println("failed to clone or update repository: %w", err)
				}
			}

			response, err := request.StartImportServiceRequest(serviceName, workdir, importData.Image, importWorkdir, cluster)
			if err != nil {
				return err
			}

			fmt.Printf("Response: %s\n", response)
			return nil
		}

		var image string
		if _, err := os.Stat(containerFilePath); err == nil {
			containerData, err := business_logic.ReadContainerFile(containerFilePath)
			if err != nil {
				fmt.Println("failed to read container file:", err)
			} else {
				image = containerData.Image // Captura a imagem se disponível
			}
		}

		serveMode, err := cmd.Flags().GetBool("serve")
		if err != nil {
			return fmt.Errorf("failed to parse flag --serve: %w", err)
		}

		if serveMode {
			response, err := request.StartServeServiceRequest(serviceName, workdir, image, cluster)
			if err != nil {
				return err
			}
			fmt.Printf("Response: %s\n", response)
		} else {
			// Call external function to start the service
			response, err := request.StartServiceRequest(serviceName, workdir, image)
			if err != nil {
				return err
			}
			fmt.Printf("Response: %s\n", response)
		}

		return nil
	},
}

func init() {
	serviceStartCmd.Flags().Bool("serve", false, "Run the service in continuous mode")
	GetServiceCmd().AddCommand(serviceStartCmd)
}
