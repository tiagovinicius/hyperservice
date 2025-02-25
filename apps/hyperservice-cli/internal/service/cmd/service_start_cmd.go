package cmd

import (
	"fmt"

	rootCmd "hyperservice-cli/cmd"
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