package cmd

import (
	rootCmd "hyperservice-cli/cmd" // Import root command to register `meshCmd`

	"github.com/spf13/cobra"
)

// meshCmd represents the base command for mesh-related operations
var serviceCmd = &cobra.Command{
	Use:   "service",
	Short: "Manage services",
}

func init() {
	rootCmd.GetRootCmd().AddCommand(serviceCmd) // Register under rootCmd
}

// GetServiceCmd returns the service command
func GetServiceCmd() *cobra.Command {
	return serviceCmd
}