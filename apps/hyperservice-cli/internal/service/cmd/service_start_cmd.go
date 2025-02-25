package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	rootCmd "hyperservice-cli/cmd"
	"hyperservice-cli/internal/service/business_logic"
	"hyperservice-cli/internal/service/request"

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

		if _, err := os.Stat(importFilePath); err == nil {
			// Read container image from import.yml
			image, err := business_logic.ReadImportFile(importFilePath)
			if err != nil {
				return fmt.Errorf("failed to read import file: %w", err)
			}

			response, err := request.StartServeServiceRequest(serviceName, image)
			if err != nil {
				return err
			}

			fmt.Printf("Response: %s\n", response)
			return nil
		}

		// Call external function to start the service
		response, err := request.StartServiceRequest(serviceName, workdir)
		if err != nil {
			return err
		}

		fmt.Printf("Response: %s\n", response)
		return nil
	},
}

func init() {
	GetServiceCmd().AddCommand(serviceStartCmd)
}
