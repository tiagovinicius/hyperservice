package cmd

import (
	rootCmd "hyperservice-cli/cmd" // Import root command to register `meshCmd`

	"github.com/spf13/cobra"
)

// meshCmd represents the base command for mesh-related operations
var observabilityCmd = &cobra.Command{
	Use:   "observability",
	Short: "Manage service observability",
}

func init() {
	rootCmd.GetRootCmd().AddCommand(observabilityCmd) // Register under rootCmd
}

// GetObservabilityCmd returns the observability command
func GetObservabilityCmd() *cobra.Command {
	return observabilityCmd
}